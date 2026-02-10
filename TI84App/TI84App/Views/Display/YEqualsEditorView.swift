import SwiftUI
import TI84Core

/// Y= equation editor with 10 function slots.
struct YEqualsEditorView: View {
    @EnvironmentObject var appState: AppState
    @State private var editingIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<10, id: \.self) { i in
                let yNum = i == 9 ? 0 : i + 1
                HStack(spacing: 4) {
                    // Enable/disable indicator
                    Button(action: {
                        appState.calculatorState.toggleYVar(yNum)
                    }) {
                        Text("\\Y\(yNum)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .background(appState.calculatorState.isYVarEnabled(yNum) ?
                                       Color.black.opacity(0.2) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    Text("=")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.black)

                    if editingIndex == i {
                        TextField("", text: Binding(
                            get: { appState.calculatorState.yVarExpression(yNum) },
                            set: { appState.calculatorState.setYVarExpression(yNum, $0) }
                        ))
                        .font(.system(size: 14, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(.black)
                        .onSubmit {
                            editingIndex = nil
                        }
                    } else {
                        Text(appState.calculatorState.yVarExpression(yNum))
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingIndex = i
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }

            Spacer()
        }
        .padding(.top, 4)
    }
}
