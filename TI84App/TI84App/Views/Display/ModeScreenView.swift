import SwiftUI
import TI84Core

/// MODE screen for changing calculator settings.
struct ModeScreenView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            modeRow("Number:", options: ModeSettings.NumberFormat.allCases.map(\.rawValue),
                    selected: appState.calculatorState.modeSettings.numberFormat.rawValue) { val in
                if let fmt = ModeSettings.NumberFormat(rawValue: val) {
                    appState.calculatorState.modeSettings.numberFormat = fmt
                }
            }

            modeRow("Float:", options: ["Float", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
                    selected: floatLabel) { val in
                if val == "Float" {
                    appState.calculatorState.modeSettings.floatSetting = .float
                } else if let n = Int(val) {
                    appState.calculatorState.modeSettings.floatSetting = .fixed(n)
                }
            }

            modeRow("Angle:", options: ModeSettings.AngleUnit.allCases.map(\.rawValue),
                    selected: appState.calculatorState.modeSettings.angleUnit.rawValue) { val in
                if let unit = ModeSettings.AngleUnit(rawValue: val) {
                    appState.calculatorState.modeSettings.angleUnit = unit
                }
            }

            modeRow("Graph:", options: ModeSettings.GraphMode.allCases.map(\.rawValue),
                    selected: appState.calculatorState.modeSettings.graphMode.rawValue) { val in
                if let mode = ModeSettings.GraphMode(rawValue: val) {
                    appState.calculatorState.modeSettings.graphMode = mode
                }
            }

            modeRow("Complex:", options: ModeSettings.ComplexFormat.allCases.map(\.rawValue),
                    selected: appState.calculatorState.modeSettings.complexFormat.rawValue) { val in
                if let fmt = ModeSettings.ComplexFormat(rawValue: val) {
                    appState.calculatorState.modeSettings.complexFormat = fmt
                }
            }

            modeRow("Draw:", options: ["Connected", "Dot"],
                    selected: appState.calculatorState.modeSettings.isConnected ? "Connected" : "Dot") { val in
                appState.calculatorState.modeSettings.isConnected = (val == "Connected")
            }

            modeRow("Order:", options: ModeSettings.GraphOrder.allCases.map(\.rawValue),
                    selected: appState.calculatorState.modeSettings.graphOrder.rawValue) { val in
                if let order = ModeSettings.GraphOrder(rawValue: val) {
                    appState.calculatorState.modeSettings.graphOrder = order
                }
            }

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
    }

    private var floatLabel: String {
        switch appState.calculatorState.modeSettings.floatSetting {
        case .float: return "Float"
        case .fixed(let n): return "\(n)"
        }
    }

    @ViewBuilder
    private func modeRow(_ label: String, options: [String], selected: String, action: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                ForEach(options, id: \.self) { option in
                    Button(action: { action(option) }) {
                        Text(option)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(option == selected ? Color.black.opacity(0.25) : Color.clear)
                            .cornerRadius(2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
