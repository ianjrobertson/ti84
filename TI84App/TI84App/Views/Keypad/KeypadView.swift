import SwiftUI
import TI84Core

/// Full TI-84 button grid layout.
struct KeypadView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 2) {
            // Arrow keys (D-pad style)
            HStack(spacing: 2) {
                Spacer()
                VStack(spacing: 1) {
                    arrowButton(arrowKeys[0]) // Up
                    HStack(spacing: 8) {
                        arrowButton(arrowKeys[2]) // Left
                        arrowButton(arrowKeys[3]) // Right
                    }
                    arrowButton(arrowKeys[1]) // Down
                }
                Spacer()
            }
            .padding(.bottom, 4)

            // Main keypad rows
            ForEach(Array(keypadRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 3) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, keyDef in
                        CalculatorButton(
                            definition: keyDef,
                            action: { appState.handleKey(keyDef.key) },
                            isSecondActive: appState.secondActive,
                            isAlphaActive: appState.alphaActive || appState.alphaLock
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func arrowButton(_ keyDef: KeyDef) -> some View {
        Button(action: { appState.handleKey(keyDef.key) }) {
            Text(keyDef.primary)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(keyDef.color.background)
                )
        }
        .buttonStyle(.plain)
    }
}
