import SwiftUI

/// Program editor for TI-BASIC programs.
struct ProgramEditorView: View {
    @EnvironmentObject var appState: AppState
    let programName: String?
    @State private var name: String = ""
    @State private var source: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("PROGRAM:")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)

                if programName == nil {
                    TextField("Name", text: $name)
                        .font(.system(size: 14, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(.black)
                        .frame(width: 100)
                } else {
                    Text(programName ?? "")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 8)

            Divider().background(Color.black)

            // Source editor
            TextEditor(text: $source)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.black)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.top, 4)
        .onAppear {
            if let pName = programName {
                name = pName
                source = appState.calculatorState.programs[pName] ?? ""
            }
        }
        .onDisappear {
            // Save on exit
            if !name.isEmpty {
                appState.calculatorState.programs[name] = source
            }
        }
    }
}
