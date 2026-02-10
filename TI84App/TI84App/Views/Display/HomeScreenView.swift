import SwiftUI
import TI84Core

/// Home screen: expression input and result history display.
struct HomeScreenView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // History area (scrollable)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(appState.calculatorState.history.enumerated()), id: \.offset) { idx, entry in
                            VStack(alignment: .leading, spacing: 1) {
                                // Expression (left-aligned)
                                Text(entry.expression)
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Result (right-aligned)
                                Text(entry.result)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .id(idx)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }
                .onChange(of: appState.calculatorState.history.count) { _ in
                    if let last = appState.calculatorState.history.indices.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // Current input line with cursor
            HStack(spacing: 0) {
                Text(currentInputWithCursor)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
    }

    private var currentInputWithCursor: String {
        let expr = appState.currentExpression
        let pos = min(appState.cursorPosition, expr.count)
        let before = String(expr.prefix(pos))
        let after = String(expr.dropFirst(pos))
        return before + "▮" + after
    }
}
