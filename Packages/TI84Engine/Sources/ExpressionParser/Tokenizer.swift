import Foundation
import TI84Core

/// Converts a TI-84 expression string into a sequence of tokens.
/// Handles implicit multiplication insertion and negation vs subtraction disambiguation.
public struct Tokenizer {
    private let input: [Character]
    private var pos: Int = 0

    public init(_ input: String) {
        self.input = Array(input)
    }

    public mutating func tokenize() throws -> [PositionedToken] {
        var tokens: [PositionedToken] = []

        while pos < input.count {
            skipWhitespace()
            guard pos < input.count else { break }

            let startPos = pos
            let ch = input[pos]

            // Check for implicit multiplication before this token
            if let last = tokens.last?.token, shouldInsertImplicitMultiply(before: ch, after: last) {
                tokens.append(PositionedToken(token: .implicitMultiply, position: startPos))
            }

            let token = try readToken()
            tokens.append(PositionedToken(token: token, position: startPos))
        }

        tokens.append(PositionedToken(token: .eof, position: pos))

        // Post-process: convert minus to negate based on context
        tokens = disambiguateNegation(tokens)

        return tokens
    }

    // MARK: - Token Reading

    private mutating func readToken() throws -> Token {
        let ch = input[pos]

        // Numbers
        if ch.isNumber || (ch == "." && pos + 1 < input.count && input[pos + 1].isNumber) {
            return try readNumber()
        }

        // Strings
        if ch == "\"" {
            return try readString()
        }

        // Operators and punctuation
        switch ch {
        case "+": pos += 1; return .plus
        case "*", "×": pos += 1; return .multiply
        case "/", "÷": pos += 1; return .divide
        case "^": pos += 1; return .power
        case "(": pos += 1; return .leftParen
        case ")": pos += 1; return .rightParen
        case "[": return try readBracketedName()
        case "{": pos += 1; return .leftBrace
        case "}": pos += 1; return .rightBrace
        case ",": pos += 1; return .comma
        case "!": pos += 1; return .factorial
        case "→", "▸": pos += 1; return .store
        case "-", "−": pos += 1; return .minus
        case "²": pos += 1; return .function(.sqrt) // will be handled as postfix in parser
        case "=": pos += 1; return .equal
        case "<":
            pos += 1
            if pos < input.count && input[pos] == "=" { pos += 1; return .lessEqual }
            return .lessThan
        case ">":
            pos += 1
            if pos < input.count && input[pos] == "=" { pos += 1; return .greaterEqual }
            return .greaterThan
        case "≠": pos += 1; return .notEqual
        case "≤": pos += 1; return .lessEqual
        case "≥": pos += 1; return .greaterEqual
        case "π": pos += 1; return .pi
        case "θ": pos += 1; return .variable("θ")
        case "√":
            pos += 1
            if pos < input.count && input[pos] == "(" { pos += 1 }
            return .function(.sqrt)
        case "ᴇ", "ₑ":
            pos += 1; return .eulerE
        default:
            break
        }

        // Keywords and function names
        if ch.isLetter || ch == "∟" {
            return try readWord()
        }

        // Negative sign token: TI-84 uses special char
        if ch == "⁻" || ch == "‾" {
            pos += 1
            return .negate
        }

        throw CalcError.syntax
    }

    // MARK: - Number Reading

    private mutating func readNumber() throws -> Token {
        var numStr = ""

        // Integer part
        while pos < input.count && input[pos].isNumber {
            numStr.append(input[pos])
            pos += 1
        }

        // Decimal part
        if pos < input.count && input[pos] == "." {
            numStr.append(".")
            pos += 1
            while pos < input.count && input[pos].isNumber {
                numStr.append(input[pos])
                pos += 1
            }
        }

        // Scientific notation (E or ᴇ)
        if pos < input.count && (input[pos] == "E" || input[pos] == "ᴇ") {
            // Only treat as sci notation if followed by digit or +/-
            let next = pos + 1 < input.count ? input[pos + 1] : Character(" ")
            if next.isNumber || next == "+" || next == "-" || next == "−" {
                numStr.append("E")
                pos += 1
                if input[pos] == "+" || input[pos] == "-" || input[pos] == "−" {
                    if input[pos] == "−" { numStr.append("-") } else { numStr.append(input[pos]) }
                    pos += 1
                }
                while pos < input.count && input[pos].isNumber {
                    numStr.append(input[pos])
                    pos += 1
                }
            }
        }

        guard let value = Double(numStr) else {
            throw CalcError.syntax
        }
        return .number(value)
    }

    // MARK: - String Reading

    private mutating func readString() throws -> Token {
        pos += 1 // skip opening "
        var str = ""
        while pos < input.count && input[pos] != "\"" {
            str.append(input[pos])
            pos += 1
        }
        if pos < input.count { pos += 1 } // skip closing "
        return .string(str)
    }

    // MARK: - Bracket Name ([A] - [J] for matrices)

    private mutating func readBracketedName() throws -> Token {
        pos += 1 // skip [
        var name = ""
        while pos < input.count && input[pos] != "]" {
            name.append(input[pos])
            pos += 1
        }
        guard pos < input.count else { throw CalcError.syntax }
        pos += 1 // skip ]
        return .matrixName(name)
    }

    // MARK: - Word Reading (functions, variables, keywords)

    private mutating func readWord() throws -> Token {
        // Custom list name: ∟NAME
        if input[pos] == "∟" {
            pos += 1
            var name = ""
            while pos < input.count && (input[pos].isLetter || input[pos].isNumber) && name.count < 5 {
                name.append(input[pos])
                pos += 1
            }
            return .listName(name)
        }

        var word = ""
        let startPos = pos
        while pos < input.count && (input[pos].isLetter || input[pos].isNumber || input[pos] == "⁻" || input[pos] == "¹") {
            word.append(input[pos])
            pos += 1
        }

        // Check for opening paren (function call)
        let hasParen = pos < input.count && input[pos] == "("

        // Functions with paren
        if hasParen {
            if let fn = matchFunction(word) {
                pos += 1 // consume the (
                return .function(fn)
            }
        }

        // Keywords and special tokens
        switch word {
        case "sin":
            if hasParen { pos += 1; return .function(.sin) }
            return .function(.sin)
        case "cos":
            if hasParen { pos += 1; return .function(.cos) }
            return .function(.cos)
        case "tan":
            if hasParen { pos += 1; return .function(.tan) }
            return .function(.tan)
        case "sin⁻¹", "asin":
            if hasParen { pos += 1 }; return .function(.asin)
        case "cos⁻¹", "acos":
            if hasParen { pos += 1 }; return .function(.acos)
        case "tan⁻¹", "atan":
            if hasParen { pos += 1 }; return .function(.atan)
        case "sinh":
            if hasParen { pos += 1 }; return .function(.sinh)
        case "cosh":
            if hasParen { pos += 1 }; return .function(.cosh)
        case "tanh":
            if hasParen { pos += 1 }; return .function(.tanh)
        case "log":
            if hasParen { pos += 1 }; return .function(.log)
        case "ln":
            if hasParen { pos += 1 }; return .function(.ln)
        case "abs":
            if hasParen { pos += 1 }; return .function(.abs)
        case "sqrt", "√":
            if hasParen { pos += 1 }; return .function(.sqrt)
        case "round":
            if hasParen { pos += 1 }; return .function(.round)
        case "iPart":
            if hasParen { pos += 1 }; return .function(.iPart)
        case "fPart":
            if hasParen { pos += 1 }; return .function(.fPart)
        case "int":
            if hasParen { pos += 1 }; return .function(.int_)
        case "min":
            if hasParen { pos += 1 }; return .function(.min)
        case "max":
            if hasParen { pos += 1 }; return .function(.max)
        case "lcm":
            if hasParen { pos += 1 }; return .function(.lcm)
        case "gcd":
            if hasParen { pos += 1 }; return .function(.gcd)
        case "dim":
            if hasParen { pos += 1 }; return .function(.dim)
        case "sum":
            if hasParen { pos += 1 }; return .function(.sum)
        case "prod":
            if hasParen { pos += 1 }; return .function(.prod)
        case "mean":
            if hasParen { pos += 1 }; return .function(.mean)
        case "median":
            if hasParen { pos += 1 }; return .function(.median)
        case "seq":
            if hasParen { pos += 1 }; return .function(.seq)
        case "cumSum":
            if hasParen { pos += 1 }; return .function(.cumSum)
        case "augment":
            if hasParen { pos += 1 }; return .function(.augment)
        case "det":
            if hasParen { pos += 1 }; return .function(.det)
        case "identity":
            if hasParen { pos += 1 }; return .function(.identity)
        case "ref":
            if hasParen { pos += 1 }; return .function(.ref)
        case "rref":
            if hasParen { pos += 1 }; return .function(.rref)
        case "randM":
            if hasParen { pos += 1 }; return .function(.randM)
        case "Fill":
            if hasParen { pos += 1 }; return .function(.fill)
        case "length":
            if hasParen { pos += 1 }; return .function(.length)
        case "sub":
            if hasParen { pos += 1 }; return .function(.sub)
        case "inString":
            if hasParen { pos += 1 }; return .function(.inString)
        case "expr":
            if hasParen { pos += 1 }; return .function(.expr)
        case "nDeriv":
            if hasParen { pos += 1 }; return .function(.nDeriv)
        case "fnInt":
            if hasParen { pos += 1 }; return .function(.fnInt)
        case "solve":
            if hasParen { pos += 1 }; return .function(.solve)
        case "normalPdf":
            if hasParen { pos += 1 }; return .function(.normalPdf)
        case "normalCdf":
            if hasParen { pos += 1 }; return .function(.normalCdf)
        case "invNorm":
            if hasParen { pos += 1 }; return .function(.invNorm)
        case "binompdf":
            if hasParen { pos += 1 }; return .function(.binomPdf)
        case "binomcdf":
            if hasParen { pos += 1 }; return .function(.binomCdf)
        case "randInt":
            if hasParen { pos += 1 }; return .function(.randInt)
        case "randNorm":
            if hasParen { pos += 1 }; return .function(.randNorm)
        case "randBin":
            if hasParen { pos += 1 }; return .function(.randBin)
        case "nPr": return .nPr
        case "nCr": return .nCr
        case "and": return .and
        case "or": return .or
        case "xor": return .xor
        case "not":
            if hasParen { pos += 1 }; return .not
        case "Ans": return .ans
        case "pi", "π": return .pi
        case "e":
            // Single 'e' is Euler's number, not a variable
            return .eulerE
        case "i":
            return .imaginaryI
        case "rand": return .function(.rand)
        case "X", "Y", "Z", "T", "A", "B", "C", "D", "F", "G", "H", "I",
             "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "U", "V", "W":
            return .variable(word)
        default:
            break
        }

        // List variables: L1-L6 or L with subscript
        if word.hasPrefix("L") && word.count == 2 {
            let digit = word.dropFirst()
            if let n = Int(digit), n >= 1 && n <= 6 {
                return .listName("L\(n)")
            }
        }

        // Y-variables: Y1-Y9, Y0
        if word.hasPrefix("Y") && word.count == 2 {
            let digit = word.dropFirst()
            if let n = Int(digit), n >= 0 && n <= 9 {
                return .yVar(n)
            }
        }

        // String variables: Str0-Str9
        if word.hasPrefix("Str") && word.count == 4 {
            let digit = word.dropFirst(3)
            if let n = Int(digit), n >= 0 && n <= 9 {
                return .stringVar("Str\(n)")
            }
        }

        // Single letter = variable
        if word.count == 1 && word.first!.isLetter {
            return .variable(word)
        }

        // If we can't identify it, try to split it into individual letters (implicit mul chain)
        // e.g., "AB" → variable A, implicit mul, variable B
        if word.count > 1 && word.allSatisfy({ $0.isUpperCase }) {
            // Reset position and just take first character
            pos = startPos + 1
            return .variable(String(word.first!))
        }

        throw CalcError.syntax
    }

    // MARK: - Function Matching

    private func matchFunction(_ name: String) -> BuiltinFunction? {
        switch name {
        case "10^": return .tenPow
        case "e^": return .ePow
        case "³√": return .cbrt
        default: return nil
        }
    }

    // MARK: - Implicit Multiplication

    /// Determines whether to insert an implicit multiply token between the previous
    /// token and the current character.
    private func shouldInsertImplicitMultiply(before ch: Character, after lastToken: Token) -> Bool {
        // Last token must be something that can be "followed by" a multiply
        let lastIsValue: Bool
        switch lastToken {
        case .number, .pi, .eulerE, .imaginaryI, .ans, .rightParen, .rightBracket, .rightBrace, .factorial:
            lastIsValue = true
        case .variable, .listName, .matrixName, .stringVar, .yVar:
            lastIsValue = true
        default:
            lastIsValue = false
        }

        guard lastIsValue else { return false }

        // Current token must be something that starts a new value
        if ch.isNumber || ch == "." { return true }
        if ch == "(" { return true }
        if ch == "[" { return true }
        if ch == "{" { return true }
        if ch.isLetter && ch != "E" { return true }
        if ch == "π" || ch == "θ" { return true }
        if ch == "√" { return true }
        if ch == "∟" { return true }

        return false
    }

    // MARK: - Negation Disambiguation

    /// Converts `.minus` to `.negate` based on context.
    /// On TI-84: (-) after operator/lparen/start/comma = negation; after value = subtraction.
    private func disambiguateNegation(_ tokens: [PositionedToken]) -> [PositionedToken] {
        var result: [PositionedToken] = []

        for (i, pt) in tokens.enumerated() {
            if pt.token == .minus {
                let isNegation: Bool
                if i == 0 {
                    isNegation = true
                } else {
                    let prev = tokens[i - 1].token
                    switch prev {
                    case .number, .pi, .eulerE, .imaginaryI, .ans,
                         .rightParen, .rightBracket, .rightBrace,
                         .variable, .listName, .matrixName, .stringVar, .yVar,
                         .factorial:
                        isNegation = false
                    default:
                        isNegation = true
                    }
                }
                if isNegation {
                    result.append(PositionedToken(token: .negate, position: pt.position))
                } else {
                    result.append(pt)
                }
            } else if pt.token == .negate {
                // Already marked as negate (from ⁻ character)
                result.append(pt)
            } else {
                result.append(pt)
            }
        }

        return result
    }

    // MARK: - Helpers

    private mutating func skipWhitespace() {
        while pos < input.count && input[pos] == " " {
            pos += 1
        }
    }
}

private extension Character {
    var isUpperCase: Bool {
        self.isLetter && self.isUppercase
    }
}
