import SwiftUI
import TI84Core
import TI84Engine

/// Table view showing function values in a grid.
struct TableScreenView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("X")
                    .frame(width: 80, alignment: .center)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)

                // Show enabled Y-var columns
                ForEach(enabledYVars, id: \.self) { yNum in
                    Text("Y\(yNum)")
                        .frame(width: 80, alignment: .center)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                }
            }
            .background(Color(red: 0.68, green: 0.72, blue: 0.62))

            Divider().background(Color.black)

            // Table rows
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(appState.tableVM.rows.indices, id: \.self) { idx in
                        let row = appState.tableVM.rows[idx]
                        HStack(spacing: 0) {
                            Text(formatValue(row.x))
                                .frame(width: 80, alignment: .trailing)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.trailing, 4)

                            ForEach(row.yValues.indices, id: \.self) { col in
                                Text(row.yValues[col])
                                    .frame(width: 80, alignment: .trailing)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.trailing, 4)
                            }
                        }
                        .background(idx == appState.tableVM.selectedRow ?
                                   Color.black.opacity(0.15) : Color.clear)
                    }
                }
            }
        }
        .onAppear {
            appState.tableVM.generateTable()
        }
    }

    private var enabledYVars: [Int] {
        (1...9).filter { appState.calculatorState.isYVarEnabled($0) &&
            !appState.calculatorState.yVarExpression($0).isEmpty } +
        (appState.calculatorState.isYVarEnabled(0) &&
         !appState.calculatorState.yVarExpression(0).isEmpty ? [0] : [])
    }

    private func formatValue(_ value: Double) -> String {
        let formatter = TI84NumberFormatter(settings: appState.calculatorState.modeSettings)
        return formatter.formatReal(value)
    }
}
