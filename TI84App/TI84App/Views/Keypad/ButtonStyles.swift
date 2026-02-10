import SwiftUI

/// Button style that mimics TI-84 calculator button press feedback.
struct CalculatorButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ?
                          backgroundColor.opacity(0.7) :
                          backgroundColor)
                    .shadow(color: .black.opacity(0.3),
                            radius: configuration.isPressed ? 0 : 2,
                            x: 0,
                            y: configuration.isPressed ? 0 : 2)
            )
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeOut(duration: 0.05), value: configuration.isPressed)
    }
}
