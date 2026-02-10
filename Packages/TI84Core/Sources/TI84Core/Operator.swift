import Foundation

/// Operator precedence levels matching TI-84 behavior.
/// Higher number = tighter binding.
public enum Precedence: Int, Comparable, Sendable {
    case store = 1          // →
    case logicalOr = 2      // or, xor
    case logicalAnd = 3     // and
    case logicalNot = 4     // not(
    case comparison = 5     // =, ≠, <, >, ≤, ≥
    case addition = 6       // +, -
    case multiplication = 7 // ×, ÷
    case negation = 8       // unary (-)
    case exponent = 9       // ^
    case postfix = 10       // ², !, °, ᵣ, ᵀ

    public static func < (lhs: Precedence, rhs: Precedence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Associativity for binary operators.
public enum Associativity: Sendable {
    case left
    case right
}

/// Operator metadata used by the Pratt parser.
public struct OperatorInfo: Sendable {
    public let precedence: Precedence
    public let associativity: Associativity

    public init(precedence: Precedence, associativity: Associativity) {
        self.precedence = precedence
        self.associativity = associativity
    }

    /// The minimum binding power for left-denotation parsing.
    public var minBP: Int {
        switch associativity {
        case .left: return precedence.rawValue * 2
        case .right: return precedence.rawValue * 2 - 1
        }
    }

    public static let add = OperatorInfo(precedence: .addition, associativity: .left)
    public static let subtract = OperatorInfo(precedence: .addition, associativity: .left)
    public static let multiply = OperatorInfo(precedence: .multiplication, associativity: .left)
    public static let divide = OperatorInfo(precedence: .multiplication, associativity: .left)
    public static let power = OperatorInfo(precedence: .exponent, associativity: .right)
    public static let negate = OperatorInfo(precedence: .negation, associativity: .right)
    public static let store = OperatorInfo(precedence: .store, associativity: .right)
    public static let comparison = OperatorInfo(precedence: .comparison, associativity: .left)
    public static let logicalAnd = OperatorInfo(precedence: .logicalAnd, associativity: .left)
    public static let logicalOr = OperatorInfo(precedence: .logicalOr, associativity: .left)
}
