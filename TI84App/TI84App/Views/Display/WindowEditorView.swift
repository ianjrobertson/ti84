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

            WindowField(label: "Xmin=", value: windowBinding(\.xMin))
            WindowField(label: "Xmax=", value: windowBinding(\.xMax))
            WindowField(label: "Xscl=", value: windowBinding(\.xScl))
            WindowField(label: "Ymin=", value: windowBinding(\.yMin))
            WindowField(label: "Ymax=", value: windowBinding(\.yMax))
            WindowField(label: "Yscl=", value: windowBinding(\.yScl))
            WindowIntField(label: "Xres=", value: windowIntBinding(\.xRes))

            Spacer()
        }
        .padding(.top, 4)
    }

    private func windowBinding(_ keyPath: WritableKeyPath<WindowParameters, Double>) -> Binding<Double> {
        Binding(
            get: { appState.calculatorState.windowParameters[keyPath: keyPath] },
            set: { appState.calculatorState.windowParameters[keyPath: keyPath] = $0 }
        )
    }

    private func windowIntBinding(_ keyPath: WritableKeyPath<WindowParameters, Int>) -> Binding<Int> {
        Binding(
            get: { appState.calculatorState.windowParameters[keyPath: keyPath] },
            set: { appState.calculatorState.windowParameters[keyPath: keyPath] = $0 }
        )
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
