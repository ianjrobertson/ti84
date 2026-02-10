import SwiftUI

/// Status bar showing 2nd/ALPHA/angle mode indicators.
struct StatusBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            if appState.secondActive {
                Text("2nd")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }

            if appState.alphaLock {
                Text("A-LOCK")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            } else if appState.alphaActive {
                Text("ALPHA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }

            Spacer()

            // Angle mode indicator
            Text(appState.calculatorState.modeSettings.angleUnit == .radian ? "RAD" : "DEG")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)

            // Screen indicator
            Text(appState.activeScreen.title)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
    }
}
