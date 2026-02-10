import Foundation
import TI84Core

/// Pratt parser that converts a token stream into an AST.
/// Handles 9+ precedence levels, right-associative ^, prefix functions, and postfix operators.
public class Parser {
    private var tokens: [PositionedToken]
    private var pos: Int = 0

    public init(tokens: [PositionedToken]) {
        self.tokens = tokens
    }

    public convenience init(expression: String) throws {
        var tokenizer = Tokenizer(expression)
        let tokens = try tokenizer.tokenize()
        self.init(tokens: tokens)
    }

    /// Parse a complete expression.
    public func parse() throws -> ASTNode {
        let node = try parseExpression(minBP: 0)
        // Allow EOF or remaining tokens for multi-statement contexts
        return node
    }

    // MARK: - Pratt Parser Core

    /// Parse an expression with minimum binding power.
    private func parseExpression(minBP: Int) throws -> ASTNode {
        var left = try parseNud()

        while true {
            let token = peek()

            // Handle store operator separately (not a BinaryOp)
            if token == .store {
                let storeInfo = OperatorInfo.store
                guard storeInfo.minBP >= minBP else { break }
                advance()
                let target = try parseExpression(minBP: storeInfo.minBP)
                left = .store(left, target)
                continue
            }

            guard let (op, info) = infixInfo(for: token) else { break }
            guard info.minBP >= minBP else { break }

            advance()

            let nextMinBP = info.associativity == .left ? info.minBP + 1 : info.minBP
            let right = try parseExpression(minBP: nextMinBP)
            left = .binary(op, left, right)
        }

        // Postfix operators
        left = try parsePostfix(left)

        return left
    }

    /// Null denotation: handles prefix tokens (numbers, variables, unary operators, functions).
    private func parseNud() throws -> ASTNode {
        let token = peek()

        switch token {
        case .number(let v):
            advance()
            return .number(v)

        case .string(let s):
            advance()
            return .string(s)

        case .pi:
            advance()
            return .pi

        case .eulerE:
            advance()
            return .eulerE

        case .imaginaryI:
            advance()
            return .imaginaryI

        case .ans:
            advance()
            return .ans

        case .variable(let name):
            advance()
            return .variable(name)

        case .listName(let name):
            advance()
            let node = ASTNode.listVar(name)
            // Check for element access: L1(3)
            if peek() == .leftParen {
                return try parseElementAccess(node)
            }
            return node

        case .matrixName(let name):
            advance()
            let node = ASTNode.matrixVar(name)
            // Check for element access: [A](2,3)
            if peek() == .leftParen {
                return try parseElementAccess(node)
            }
            return node

        case .stringVar(let name):
            advance()
            return .stringVar(name)

        case .yVar(let n):
            advance()
            let node = ASTNode.yVar(n)
            if peek() == .leftParen {
                return try parseElementAccess(node)
            }
            return node

        case .negate:
            advance()
            let operand = try parseExpression(minBP: OperatorInfo.negate.minBP)
            return .unaryPrefix(.negate, operand)

        case .not:
            advance()
            let operand = try parseExpression(minBP: Precedence.logicalNot.rawValue * 2)
            if peek() == .rightParen { advance() }
            return .unaryPrefix(.logicalNot, operand)

        case .minus:
            // Should have been converted to negate, but handle defensively
            advance()
            let operand = try parseExpression(minBP: OperatorInfo.negate.minBP)
            return .unaryPrefix(.negate, operand)

        case .leftParen:
            advance()
            let expr = try parseExpression(minBP: 0)
            try expect(.rightParen)
            return expr

        case .leftBrace:
            return try parseListLiteral()

        case .leftBracket:
            return try parseMatrixLiteral()

        case .function(let fn):
            advance()
            return try parseFunctionCall(fn)

        case .implicitMultiply:
            // Skip implicit multiply in nud position (shouldn't happen normally)
            advance()
            return try parseNud()

        default:
            throw CalcError.syntax
        }
    }

    // MARK: - Infix Operator Info

    private func infixInfo(for token: Token) -> (BinaryOp, OperatorInfo)? {
        switch token {
        case .plus: return (.add, .add)
        case .minus: return (.subtract, .subtract)
        case .multiply: return (.multiply, .multiply)
        case .divide: return (.divide, .divide)
        case .power: return (.power, .power)
        case .implicitMultiply: return (.multiply, .multiply)
        case .nPr: return (.nPr, OperatorInfo(precedence: .multiplication, associativity: .left))
        case .nCr: return (.nCr, OperatorInfo(precedence: .multiplication, associativity: .left))
        case .equal: return (.equal, .comparison)
        case .notEqual: return (.notEqual, .comparison)
        case .lessThan: return (.lessThan, .comparison)
        case .greaterThan: return (.greaterThan, .comparison)
        case .lessEqual: return (.lessEqual, .comparison)
        case .greaterEqual: return (.greaterEqual, .comparison)
        case .and: return (.logicalAnd, .logicalAnd)
        case .or: return (.logicalOr, .logicalOr)
        case .xor: return (.logicalXor, .logicalOr)
        default: return nil
        }
    }

    // MARK: - Postfix Operators

    private func parsePostfix(_ node: ASTNode) throws -> ASTNode {
        var result = node

        while true {
            let token = peek()
            switch token {
            case .factorial:
                advance()
                result = .unaryPostfix(result, .factorial)
            default:
                return result
            }
        }
    }

    // MARK: - Function Call Parsing

    private func parseFunctionCall(_ fn: BuiltinFunction) throws -> ASTNode {
        // Some functions don't take arguments (like rand)
        if fn == .rand, case .rightParen = peek() {
            return .functionCall(fn, [])
        }
        if fn == .rand && peek() == .eof {
            return .functionCall(fn, [])
        }

        var args: [ASTNode] = []

        // Parse first argument
        if peek() != .rightParen && peek() != .eof {
            args.append(try parseExpression(minBP: 0))
        }

        // Parse remaining arguments separated by commas
        while peek() == .comma {
            advance()
            args.append(try parseExpression(minBP: 0))
        }

        // Consume closing paren if present
        if peek() == .rightParen {
            advance()
        }

        return .functionCall(fn, args)
    }

    // MARK: - Element Access

    private func parseElementAccess(_ node: ASTNode) throws -> ASTNode {
        advance() // consume (
        var indices: [ASTNode] = []
        indices.append(try parseExpression(minBP: 0))
        while peek() == .comma {
            advance()
            indices.append(try parseExpression(minBP: 0))
        }
        try expect(.rightParen)
        return .elementAccess(node, indices)
    }

    // MARK: - List Literal

    private func parseListLiteral() throws -> ASTNode {
        advance() // consume {
        var elements: [ASTNode] = []

        if peek() != .rightBrace {
            elements.append(try parseExpression(minBP: 0))
            while peek() == .comma {
                advance()
                elements.append(try parseExpression(minBP: 0))
            }
        }

        try expect(.rightBrace)
        return .listLiteral(elements)
    }

    // MARK: - Matrix Literal

    private func parseMatrixLiteral() throws -> ASTNode {
        advance() // consume [
        var rows: [[ASTNode]] = []

        while peek() == .leftBracket {
            advance()
            var row: [ASTNode] = []
            row.append(try parseExpression(minBP: 0))
            while peek() == .comma {
                advance()
                row.append(try parseExpression(minBP: 0))
            }
            try expect(.rightBracket)
            rows.append(row)
            if peek() == .comma { advance() }
        }

        try expect(.rightBracket)
        return .matrixLiteral(rows)
    }

    // MARK: - Store Expression

    /// Parse a store expression: expr → var
    public func parseStore() throws -> ASTNode {
        let expr = try parseExpression(minBP: 0)
        if peek() == .store {
            advance()
            let target = try parseNud()
            return .store(expr, target)
        }
        return expr
    }

    // MARK: - Helpers

    private func peek() -> Token {
        guard pos < tokens.count else { return .eof }
        return tokens[pos].token
    }

    @discardableResult
    private func advance() -> Token {
        let token = peek()
        pos += 1
        return token
    }

    private func expect(_ expected: Token) throws {
        let actual = peek()
        guard actual == expected else {
            throw CalcError.syntax
        }
        advance()
    }
}
