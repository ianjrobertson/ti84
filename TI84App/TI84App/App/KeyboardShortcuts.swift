import SwiftUI
import TI84Core

/// Maps macOS keyboard input to CalcKey presses.
struct KeyboardShortcutHandler {
    /// Convert a macOS key event to a CalcKey.
    static func mapKeyEvent(_ event: NSEvent) -> CalcKey? {
        // Check for special keys first
        switch event.keyCode {
        case 36: return .enter      // Return
        case 51: return .del        // Delete/Backspace
        case 53: return .clear      // Escape
        case 123: return .left      // Left arrow
        case 124: return .right     // Right arrow
        case 125: return .down      // Down arrow
        case 126: return .up        // Up arrow
        default: break
        }

        // Check characters
        guard let chars = event.characters, let ch = chars.first else { return nil }

        switch ch {
        // Digits
        case "0": return .num0
        case "1": return .num1
        case "2": return .num2
        case "3": return .num3
        case "4": return .num4
        case "5": return .num5
        case "6": return .num6
        case "7": return .num7
        case "8": return .num8
        case "9": return .num9
        case ".": return .decimal

        // Operators
        case "+": return .add
        case "-": return .subtract
        case "*": return .multiply
        case "/": return .divide
        case "^": return .power
        case "(": return .leftParen
        case ")": return .rightParen
        case ",": return .comma
        case "!": return event.modifierFlags.contains(.shift) ? .inverse : nil

        // Letters (for ALPHA input)
        case "x", "X": return .xTThetaN
        case "y", "Y": return .y_equals
        case "s": return .sin
        case "c": return .cos
        case "t": return .tan

        // Function keys
        case "l": return .log
        case "n": return .ln
        case "e": return .ee

        // Special
        case "=": return .enter
        case "\u{7F}": return .del  // Forward delete

        default:
            // Handle alphabetic input
            if ch.isLetter {
                return nil // Will be handled by text input
            }
            return nil
        }
    }
}
