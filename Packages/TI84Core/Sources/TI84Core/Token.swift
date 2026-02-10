import Foundation

/// Tokens produced by the tokenizer and consumed by the parser.
public enum Token: Equatable, Sendable {
    // Literals
    case number(Double)
    case string(String)

    // Identifiers and variables
    case variable(String)         // A-Z, θ
    case listName(String)         // ∟name or L1-L6
    case matrixName(String)       // [A]-[J]
    case stringVar(String)        // Str0-Str9
    case yVar(Int)                // Y1-Y0 (0=10)

    // Operators
    case plus
    case minus
    case multiply
    case divide
    case power
    case negate                   // Unary negation (different from minus)
    case factorial
    case nPr
    case nCr
    case store                    // →

    // Comparison operators
    case equal
    case notEqual
    case lessThan
    case greaterThan
    case lessEqual
    case greaterEqual

    // Logical operators
    case and
    case or
    case xor
    case not

    // Grouping
    case leftParen
    case rightParen
    case leftBracket              // [
    case rightBracket             // ]
    case leftBrace                // {
    case rightBrace               // }
    case comma

    // Built-in functions
    case function(BuiltinFunction)

    // Constants
    case pi
    case eulerE
    case imaginaryI

    // Special
    case ans
    case implicitMultiply         // Inserted by tokenizer

    // End of input
    case eof
}

/// Represents a token with its position in the source string.
public struct PositionedToken: Equatable, Sendable {
    public let token: Token
    public let position: Int

    public init(token: Token, position: Int) {
        self.token = token
        self.position = position
    }
}
