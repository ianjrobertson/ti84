import SwiftUI

/// Program I/O screen for running TI-BASIC programs.
struct ProgramIOView: View {
    @EnvironmentObject var appState: AppState
    @State private var outputLines: [String] = []
    @State private var inputText: String = ""
    @State private var waitingForInput: Bool = false
    @State private var inputPrompt: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(outputLines.indices, id: \.self) { idx in
                        Text(outputLines[idx])
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            if waitingForInput {
                HStack {
                    Text(inputPrompt)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.black)

                    TextField("", text: $inputText)
                        .font(.system(size: 14, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(.black)
                        .onSubmit {
                            // Handle input submission
                        }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
        }
        .padding(.top, 4)
    }
}
