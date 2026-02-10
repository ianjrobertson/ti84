import SwiftUI
import TI84Core

/// Window settings editor.
struct WindowEditorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WINDOW")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 8)

            WindowField(label: "Xmin=", value: $appState.calculatorState.windowParameters.xMin)
            WindowField(label: "Xmax=", value: $appState.calculatorState.windowParameters.xMax)
            WindowField(label: "Xscl=", value: $appState.calculatorState.windowParameters.xScl)
            WindowField(label: "Ymin=", value: $appState.calculatorState.windowParameters.yMin)
            WindowField(label: "Ymax=", value: $appState.calculatorState.windowParameters.yMax)
            WindowField(label: "Yscl=", value: $appState.calculatorState.windowParameters.yScl)
            WindowIntField(label: "Xres=", value: $appState.calculatorState.windowParameters.xRes)

            Spacer()
        }
        .padding(.top, 4)
    }
}

private struct WindowField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 60, alignment: .leading)

            TextField("", value: $value, format: .number)
                .font(.system(size: 14, design: .monospaced))
                .textFieldStyle(.plain)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 8)
    }
}

private struct WindowIntField: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 60, alignment: .leading)

            TextField("", value: $value, format: .number)
                .font(.system(size: 14, design: .monospaced))
                .textFieldStyle(.plain)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 8)
    }
}
