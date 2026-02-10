import Foundation
import TI84Core

/// Formats TI84Values for display on the calculator screen.
/// Supports Normal, Sci, and Eng number formats with Float/Fixed settings.
public struct TI84NumberFormatter {
    public let settings: ModeSettings

    public init(settings: ModeSettings) {
        self.settings = settings
    }

    /// Format a TI84Value for display.
    public func format(_ value: TI84Value) -> String {
        switch value {
        case .real(let v):
            return formatReal(v)
        case .complex(let r, let i):
            return formatComplex(r, i)
        case .list(let l):
            let elements = l.map { formatReal($0) }
            return "{\(elements.joined(separator: " "))}"
        case .complexList(let l):
            let elements = l.map { formatComplex($0.re, $0.im) }
            return "{\(elements.joined(separator: " "))}"
        case .matrix(let m):
            let rows = m.map { row in
                "[\(row.map { formatReal($0) }.joined(separator: " "))]"
            }
            return "[\(rows.joined(separator: "\n "))]"
        case .string(let s):
            return "\"\(s)\""
        }
    }

    /// Format a real number for display.
    public func formatReal(_ value: Double) -> String {
        guard value.isFinite else {
            if value.isNaN { return "Error" }
            return value > 0 ? "1ᴇ99" : "-1ᴇ99"
        }

        // Handle exact zero
        if value == 0 { return formatZero() }

        switch settings.numberFormat {
        case .normal:
            return formatNormal(value)
        case .sci:
            return formatSci(value)
        case .eng:
            return formatEng(value)
        }
    }

    // MARK: - Normal Format

    private func formatNormal(_ value: Double) -> String {
        let absVal = abs(value)

        // TI-84 switches to scientific notation for very small/large numbers
        if absVal < 0.001 && absVal != 0 || absVal >= 1e10 {
            return formatSci(value)
        }

        switch settings.floatSetting {
        case .float:
            return formatFloat(value, maxDigits: 10)
        case .fixed(let places):
            return formatFixed(value, places: places)
        }
    }

    // MARK: - Scientific Notation Format

    private func formatSci(_ value: Double) -> String {
        guard value != 0 else { return formatZero() }

        let exponent = floor(log10(abs(value)))
        let mantissa = value / pow(10.0, exponent)
        let expInt = Int(exponent)

        switch settings.floatSetting {
        case .float:
            let mantissaStr = formatFloat(mantissa, maxDigits: 10)
            return "\(mantissaStr)ᴇ\(expInt)"
        case .fixed(let places):
            let mantissaStr = formatFixed(mantissa, places: places)
            return "\(mantissaStr)ᴇ\(expInt)"
        }
    }

    // MARK: - Engineering Notation Format

    private func formatEng(_ value: Double) -> String {
        guard value != 0 else { return formatZero() }

        var exponent = floor(log10(abs(value)))
        // Adjust exponent to be a multiple of 3
        var mod = Int(exponent) % 3
        if mod < 0 { mod += 3 }
        exponent -= Double(mod)
        let mantissa = value / pow(10.0, exponent)
        let expInt = Int(exponent)

        switch settings.floatSetting {
        case .float:
            let mantissaStr = formatFloat(mantissa, maxDigits: 10)
            return "\(mantissaStr)ᴇ\(expInt)"
        case .fixed(let places):
            let mantissaStr = formatFixed(mantissa, places: places)
            return "\(mantissaStr)ᴇ\(expInt)"
        }
    }

    // MARK: - Helpers

    private func formatFloat(_ value: Double, maxDigits: Int) -> String {
        // Use up to maxDigits significant digits, strip trailing zeros
        let formatted = String(format: "%.\(maxDigits)g", value)

        // TI-84 displays at most 10 characters on the result line
        if formatted.count > 14 {
            return String(format: "%.9g", value)
        }

        return formatted
    }

    private func formatFixed(_ value: Double, places: Int) -> String {
        return String(format: "%.\(places)f", value)
    }

    private func formatZero() -> String {
        switch settings.floatSetting {
        case .float:
            return "0"
        case .fixed(let places):
            if places == 0 { return "0" }
            return "0." + String(repeating: "0", count: places)
        }
    }

    private func formatComplex(_ r: Double, _ i: Double) -> String {
        switch settings.complexFormat {
        case .real:
            return formatReal(r) // shouldn't get here if mode is Real
        case .rectangularABI:
            let realPart = formatReal(r)
            let imagPart = formatReal(abs(i))
            if i == 0 { return realPart }
            if r == 0 {
                if abs(i) == 1 { return i > 0 ? "i" : "-i" }
                return "\(i > 0 ? "" : "-")\(imagPart)i"
            }
            let sign = i > 0 ? "+" : "-"
            if abs(i) == 1 { return "\(realPart)\(sign)i" }
            return "\(realPart)\(sign)\(imagPart)i"
        case .polarRE:
            let magnitude = sqrt(r * r + i * i)
            let angle = atan2(i, r)
            return "\(formatReal(magnitude))e^(\(formatReal(angle))i)"
        }
    }
}
