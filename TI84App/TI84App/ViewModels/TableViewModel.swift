import Foundation
import TI84Core
import TI84Engine

/// ViewModel for the table screen.
class TableViewModel: ObservableObject {
    weak var appState: AppState?

    struct TableRow {
        let x: Double
        let yValues: [String]
    }

    @Published var rows: [TableRow] = []
    @Published var selectedRow: Int = 0

    init(appState: AppState) {
        self.appState = appState
    }

    func generateTable() {
        guard let state = appState else { return }

        let start = state.calculatorState.tableStart
        let delta = state.calculatorState.tableDelta
        let formatter = TI84NumberFormatter(settings: state.calculatorState.modeSettings)

        // Find enabled Y-vars
        var enabledYVars: [Int] = []
        for i in 1...9 {
            if state.calculatorState.isYVarEnabled(i) &&
               !state.calculatorState.yVarExpression(i).isEmpty {
                enabledYVars.append(i)
            }
        }
        if state.calculatorState.isYVarEnabled(0) &&
           !state.calculatorState.yVarExpression(0).isEmpty {
            enabledYVars.append(0)
        }

        rows = []
        for i in 0..<20 { // Generate 20 rows
            let x = start + Double(i) * delta
            var yValues: [String] = []

            for yNum in enabledYVars {
                if let y = try? state.calculatorState.evaluateYVar(yNum, x: x) {
                    yValues.append(formatter.formatReal(y))
                } else {
                    yValues.append("ERROR")
                }
            }

            rows.append(TableRow(x: x, yValues: yValues))
        }
    }

    func moveUp() {
        if selectedRow > 0 { selectedRow -= 1 }
    }

    func moveDown() {
        if selectedRow < rows.count - 1 { selectedRow += 1 }
    }
}
