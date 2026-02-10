import SwiftUI
import TI84Core

/// List editor view (STAT Edit) for editing L1-L6.
struct ListEditorView: View {
    @EnvironmentObject var appState: AppState
    private let listNames = ["L1", "L2", "L3", "L4", "L5", "L6"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                ForEach(listNames, id: \.self) { name in
                    Text(name)
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                }
            }
            .background(Color(red: 0.68, green: 0.72, blue: 0.62))
            .padding(.horizontal, 4)

            Divider().background(Color.black)

            // List data
            ScrollView {
                let maxLen = listNames.map { appState.calculatorState.lists[$0]?.count ?? 0 }.max() ?? 0
                let rowCount = max(maxLen + 1, 7) // Show at least 7 rows

                VStack(spacing: 0) {
                    ForEach(0..<rowCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(listNames, id: \.self) { name in
                                let list = appState.calculatorState.lists[name] ?? []
                                if row < list.count {
                                    Text(formatValue(list[row]))
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 2)
                                } else {
                                    Text("")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .frame(height: 20)
                        .background(row % 2 == 0 ? Color.clear : Color.black.opacity(0.05))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.top, 4)
    }

    private func formatValue(_ value: Double) -> String {
        let formatter = TI84NumberFormatter(settings: appState.calculatorState.modeSettings)
        return formatter.formatReal(value)
    }
}
