import SwiftUI
import TI84Core

/// A single calculator button with primary, 2nd, and ALPHA labels.
struct CalculatorButton: View {
    let definition: KeyDef
    let action: () -> Void
    let isSecondActive: Bool
    let isAlphaActive: Bool

    var body: some View {
        VStack(spacing: 1) {
            // 2nd function label (above button, in yellow/blue)
            if let secondLabel = definition.secondLabel {
                Text(secondLabel)
                    .font(.system(size: 8, weight: isSecondActive ? .bold : .regular))
                    .foregroundColor(isSecondActive ?
                                    Color(red: 0.85, green: 0.7, blue: 0.15) :
                                    Color(red: 0.85, green: 0.7, blue: 0.15).opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(height: 10)
            } else {
                Spacer().frame(height: 10)
            }

            // Main button
            Button(action: action) {
                VStack(spacing: 0) {
                    // ALPHA label (inside button top)
                    if let alphaLabel = definition.alphaLabel {
                        Text(alphaLabel)
                            .font(.system(size: 8, weight: isAlphaActive ? .bold : .regular))
                            .foregroundColor(isAlphaActive ?
                                            Color(red: 0.2, green: 0.7, blue: 0.3) :
                                            Color(red: 0.2, green: 0.7, blue: 0.3).opacity(0.6))
                            .frame(height: 10)
                    }

                    // Primary label
                    Text(definition.primary)
                        .font(.system(size: buttonFontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(definition.color.foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .buttonStyle(CalculatorButtonStyle(
                backgroundColor: definition.color.background,
                foregroundColor: definition.color.foreground
            ))
            .frame(height: buttonHeight)
        }
    }

    private var buttonFontSize: CGFloat {
        let len = definition.primary.count
        if len <= 2 { return 14 }
        if len <= 4 { return 11 }
        return 9
    }

    private var buttonHeight: CGFloat {
        32
    }
}
