import SwiftUI
import TI84Core

/// Static layout data for the TI-84 keypad.
struct KeyDef {
    let key: CalcKey
    let primary: String
    let secondLabel: String?
    let alphaLabel: String?
    let color: KeyColor
    let width: CGFloat // multiplier (1.0 = normal)

    init(_ key: CalcKey, _ primary: String,
         second: String? = nil, alpha: String? = nil,
         color: KeyColor = .dark, width: CGFloat = 1.0) {
        self.key = key
        self.primary = primary
        self.secondLabel = second
        self.alphaLabel = alpha
        self.color = color
        self.width = width
    }
}

enum KeyColor {
    case dark       // Dark gray
    case light      // Light gray
    case blue       // Blue (function keys)
    case green      // Green (ALPHA)
    case yellow     // Yellow (2nd)
    case black      // Black (number keys)
    case white      // White (operators)
    case enter      // Enter key blue

    var background: Color {
        switch self {
        case .dark: return Color(red: 0.25, green: 0.25, blue: 0.28)
        case .light: return Color(red: 0.55, green: 0.55, blue: 0.58)
        case .blue: return Color(red: 0.2, green: 0.3, blue: 0.6)
        case .green: return Color(red: 0.2, green: 0.55, blue: 0.25)
        case .yellow: return Color(red: 0.85, green: 0.7, blue: 0.15)
        case .black: return Color(red: 0.15, green: 0.15, blue: 0.17)
        case .white: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .enter: return Color(red: 0.15, green: 0.25, blue: 0.55)
        }
    }

    var foreground: Color {
        switch self {
        case .white, .light, .yellow: return .black
        default: return .white
        }
    }
}

/// All keypad rows, matching TI-84 Plus physical layout.
let keypadRows: [[KeyDef]] = [
    // Row 1: Y= WINDOW ZOOM TRACE GRAPH
    [
        KeyDef(.y_equals, "Y=", second: "STAT PLOT", color: .blue),
        KeyDef(.window, "WINDOW", second: "TBLSET", color: .blue),
        KeyDef(.zoom, "ZOOM", second: "FORMAT", color: .blue),
        KeyDef(.trace, "TRACE", second: "CALC", color: .blue),
        KeyDef(.graph, "GRAPH", second: "TABLE", color: .blue),
    ],
    // Row 2: 2nd MODE DEL ALPHA X,T,θ,n
    [
        KeyDef(.second, "2nd", color: .yellow),
        KeyDef(.mode, "MODE", second: "QUIT", color: .dark),
        KeyDef(.del, "DEL", second: "INS", color: .dark),
        KeyDef(.alpha, "ALPHA", second: "A-LOCK", color: .green),
        KeyDef(.xTThetaN, "X,T,θ,n", second: "LINK", color: .dark),
    ],
    // Row 3: MATH APPS PRGM VARS CLEAR
    [
        KeyDef(.math, "MATH", second: "TEST", alpha: "A", color: .dark),
        KeyDef(.apps, "APPS", second: "ANGLE", alpha: "B", color: .dark),
        KeyDef(.prgm, "PRGM", second: "DRAW", alpha: "C", color: .dark),
        KeyDef(.vars, "VARS", second: "DISTR", color: .dark),
        KeyDef(.clear, "CLEAR", color: .dark),
    ],
    // Row 4: x⁻¹ SIN COS TAN ^
    [
        KeyDef(.inverse, "x⁻¹", second: "MATRIX", alpha: "D", color: .dark),
        KeyDef(.sin, "SIN", second: "SIN⁻¹", alpha: "E", color: .dark),
        KeyDef(.cos, "COS", second: "COS⁻¹", alpha: "F", color: .dark),
        KeyDef(.tan, "TAN", second: "TAN⁻¹", alpha: "G", color: .dark),
        KeyDef(.power, "^", second: "π", alpha: "H", color: .dark),
    ],
    // Row 5: x² , ( ) ÷
    [
        KeyDef(.squared, "x²", second: "√", alpha: "I", color: .dark),
        KeyDef(.comma, ",", second: "EE", alpha: "J", color: .dark),
        KeyDef(.leftParen, "(", second: "{", alpha: "K", color: .dark),
        KeyDef(.rightParen, ")", second: "}", alpha: "L", color: .dark),
        KeyDef(.divide, "÷", second: "e", alpha: "M", color: .dark),
    ],
    // Row 6: LOG 7 8 9 ×
    [
        KeyDef(.log, "LOG", second: "10ˣ", alpha: "N", color: .dark),
        KeyDef(.num7, "7", alpha: "O", color: .black),
        KeyDef(.num8, "8", alpha: "P", color: .black),
        KeyDef(.num9, "9", alpha: "Q", color: .black),
        KeyDef(.multiply, "×", second: "[", alpha: "R", color: .dark),
    ],
    // Row 7: LN 4 5 6 −
    [
        KeyDef(.ln, "LN", second: "eˣ", alpha: "S", color: .dark),
        KeyDef(.num4, "4", alpha: "T", color: .black),
        KeyDef(.num5, "5", alpha: "U", color: .black),
        KeyDef(.num6, "6", alpha: "V", color: .black),
        KeyDef(.subtract, "−", second: "]", alpha: "W", color: .dark),
    ],
    // Row 8: STO→ 1 2 3 +
    [
        KeyDef(.store, "STO→", second: "RCL", alpha: "X", color: .dark),
        KeyDef(.num1, "1", alpha: "Y", color: .black),
        KeyDef(.num2, "2", alpha: "Z", color: .black),
        KeyDef(.num3, "3", alpha: "θ", color: .black),
        KeyDef(.add, "+", second: "MEM", alpha: "\"", color: .dark),
    ],
    // Row 9: ON 0 . (-) ENTER
    [
        KeyDef(.on, "ON", color: .dark),
        KeyDef(.num0, "0", second: "CATALOG", alpha: "SPACE", color: .black),
        KeyDef(.decimal, ".", second: "i", alpha: ":", color: .black),
        KeyDef(.negate, "(-)", second: "ANS", alpha: "?", color: .dark),
        KeyDef(.enter, "ENTER", second: "ENTRY", color: .enter),
    ],
]

/// Arrow key row
let arrowKeys: [KeyDef] = [
    KeyDef(.up, "▲", color: .dark),
    KeyDef(.down, "▼", color: .dark),
    KeyDef(.left, "◀", color: .dark),
    KeyDef(.right, "▶", color: .dark),
]
