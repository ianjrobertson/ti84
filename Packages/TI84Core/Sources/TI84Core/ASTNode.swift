import Foundation

/// Abstract syntax tree produced by the parser.
public indirect enum ASTNode: Equatable, Sendable {
    /// Numeric literal
    case number(Double)

    /// String literal
    case string(String)

    /// Variable reference (A-Z, θ)
    case variable(String)

    /// The Ans variable
    case ans

    /// List variable (L1-L6, or custom ∟name)
    case listVar(String)

    /// Matrix variable ([A]-[J])
    case matrixVar(String)

    /// String variable (Str0-Str9)
    case stringVar(String)

    /// Y-variable (Y1-Y0)
    case yVar(Int)

    /// Constants
    case pi
    case eulerE
    case imaginaryI

    /// Binary operator: left op right
    case binary(BinaryOp, ASTNode, ASTNode)

    /// Unary prefix operator
    case unaryPrefix(UnaryOp, ASTNode)

    /// Unary postfix operator
    case unaryPostfix(ASTNode, PostfixOp)

    /// Function call with arguments
    case functionCall(BuiltinFunction, [ASTNode])

    /// List literal: {1, 2, 3}
    case listLiteral([ASTNode])

    /// Matrix literal: [[1,2],[3,4]]
    case matrixLiteral([[ASTNode]])

    /// Element access: L1(3) or [A](2,3)
    case elementAccess(ASTNode, [ASTNode])

    /// Store: expression → variable
    case store(ASTNode, ASTNode)

    /// Implicit multiplication (semantically same as multiply)
    case implicitMul(ASTNode, ASTNode)
}

public enum BinaryOp: String, Equatable, Sendable {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case power = "^"
    case nPr = "nPr"
    case nCr = "nCr"
    case equal = "="
    case notEqual = "≠"
    case lessThan = "<"
    case greaterThan = ">"
    case lessEqual = "≤"
    case greaterEqual = "≥"
    case logicalAnd = "and"
    case logicalOr = "or"
    case logicalXor = "xor"
}

public enum UnaryOp: String, Equatable, Sendable {
    case negate = "-"
    case logicalNot = "not"
}

public enum PostfixOp: String, Equatable, Sendable {
    case factorial = "!"
    case squared = "²"
    case cubed = "³"
    case inverse = "⁻¹"
    case transpose = "ᵀ"
    case degrees = "°"
    case radians = "ʳ"
    case percent = "%"
}
