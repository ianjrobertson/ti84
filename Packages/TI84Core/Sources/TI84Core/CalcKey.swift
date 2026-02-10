import Foundation

/// Every physical key on the TI-84 Plus, plus 2nd/ALPHA modifiers.
/// Keys are named by their primary (unmodified) label.
public enum CalcKey: String, CaseIterable, Sendable {
    // Row 1 — top function keys
    case y_equals     // Y=
    case window       // WINDOW
    case zoom         // ZOOM
    case trace        // TRACE
    case graph        // GRAPH

    // Row 2
    case second       // 2nd
    case mode         // MODE
    case del          // DEL
    case alpha        // ALPHA
    case xTThetaN     // X,T,θ,n

    // Row 3
    case stat         // STAT
    case math         // MATH

    // Row 4 — matrix/apps row
    case apps         // APPS (2nd = MATRIX on some models)
    case prgm         // PRGM
    case vars         // VARS
    case clear        // CLEAR

    // Row 5 — inverse/trig row
    case inverse      // x^(-1)
    case sin          // sin
    case cos          // cos
    case tan          // tan
    case power        // ^

    // Row 6 — square/comma row
    case squared      // x²
    case comma        // ,
    case leftParen    // (
    case rightParen   // )
    case divide       // ÷

    // Row 7 — log row
    case log          // log
    case num7         // 7
    case num8         // 8
    case num9         // 9
    case multiply     // ×

    // Row 8 — ln row
    case ln           // ln
    case num4         // 4
    case num5         // 5
    case num6         // 6
    case subtract     // -

    // Row 9 — store row
    case store        // STO->
    case num1         // 1
    case num2         // 2
    case num3         // 3
    case add          // +

    // Row 10 — bottom row
    case on           // ON
    case num0         // 0
    case decimal      // .
    case negate       // (-)
    case enter        // ENTER

    // Arrow keys
    case up
    case down
    case left
    case right

    // MARK: - 2nd function results (virtual keys dispatched after 2nd press)
    case statPlot     // 2nd + Y=
    case tableSet     // 2nd + WINDOW
    case format       // 2nd + ZOOM
    case calc         // 2nd + TRACE
    case table        // 2nd + GRAPH

    case link         // 2nd + X,T,θ,n
    case list         // 2nd + STAT
    case test         // 2nd + MATH

    case angle        // 2nd + APPS
    case draw         // 2nd + PRGM
    case distr        // 2nd + VARS

    case matrix       // 2nd + inverse (on CE: 2nd + APPS)

    case ins          // 2nd + DEL
    case recall       // 2nd + STO
    case aLock        // 2nd + ALPHA

    case sqrt         // 2nd + squared
    case ee           // 2nd + comma
    case catalog      // 2nd + 0
    case i_imaginary  // 2nd + decimal
    case ans          // 2nd + negate
    case entry        // 2nd + enter

    case tenPower     // 2nd + log
    case ePower       // 2nd + ln

    case lBracket     // 2nd + leftParen  → [
    case rBracket     // 2nd + rightParen → ]
    case lBrace       // 2nd + (  via other mapping → {
    case rBrace       // 2nd + )  via other mapping → }

    case pi           // 2nd + ^
    case abs          // 2nd somewhere

    case quit         // 2nd + MODE

    // MARK: - Properties

    /// Whether this is a digit key
    public var isDigit: Bool {
        switch self {
        case .num0, .num1, .num2, .num3, .num4,
             .num5, .num6, .num7, .num8, .num9:
            return true
        default:
            return false
        }
    }

    /// The digit value if this is a digit key
    public var digitValue: Int? {
        switch self {
        case .num0: return 0
        case .num1: return 1
        case .num2: return 2
        case .num3: return 3
        case .num4: return 4
        case .num5: return 5
        case .num6: return 6
        case .num7: return 7
        case .num8: return 8
        case .num9: return 9
        default: return nil
        }
    }

    /// The ALPHA letter for this key (A-Z, theta, space)
    public var alphaCharacter: String? {
        switch self {
        case .math: return "A"
        case .apps: return "B"
        case .prgm: return "C"
        case .inverse: return "D"
        case .sin: return "E"
        case .cos: return "F"
        case .tan: return "G"
        case .power: return "H"
        case .squared: return "I"
        case .comma: return "J"
        case .leftParen: return "K"
        case .rightParen: return "L"
        case .divide: return "M"
        case .log: return "N"
        case .num7: return "O"
        case .num8: return "P"
        case .num9: return "Q"
        case .multiply: return "R"
        case .ln: return "S"
        case .num4: return "T"
        case .num5: return "U"
        case .num6: return "V"
        case .subtract: return "W"
        case .store: return "X"
        case .num1: return "Y"
        case .num2: return "Z"
        case .num3: return "θ"
        case .add: return "\""
        case .num0: return " "
        case .decimal: return ":"
        case .negate: return "?"
        default: return nil
        }
    }
}
