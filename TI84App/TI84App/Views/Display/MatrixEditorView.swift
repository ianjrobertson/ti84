import SwiftUI
import TI84Core

/// Matrix editor view for editing matrices [A]-[J].
struct MatrixEditorView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMatrix: String = "A"
    @State private var rows: Int = 3
    @State private var cols: Int = 3

    private let matrixNames = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Matrix selector
            HStack {
                Text("MATRIX[")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)

                Picker("", selection: $selectedMatrix) {
                    ForEach(matrixNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 50)

                Text("] \(rows)×\(cols)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 8)

            // Dimension editors
            HStack {
                Text("Rows:")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.black)
                TextField("", value: $rows, format: .number)
                    .frame(width: 30)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))

                Text("Cols:")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.black)
                TextField("", value: $cols, format: .number)
                    .frame(width: 30)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))

                Button("Apply") {
                    applyDimensions()
                }
                .font(.system(size: 11, design: .monospaced))
            }
            .padding(.horizontal, 8)

            // Matrix grid
            let matrix = appState.calculatorState.matrices[selectedMatrix] ?? emptyMatrix

            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 1) {
                    ForEach(0..<matrix.count, id: \.self) { row in
                        HStack(spacing: 1) {
                            ForEach(0..<(matrix.first?.count ?? 0), id: \.self) { col in
                                TextField("0", value: Binding(
                                    get: { matrix[row][col] },
                                    set: { newVal in
                                        var m = appState.calculatorState.matrices[selectedMatrix] ?? emptyMatrix
                                        if row < m.count && col < m[row].count {
                                            m[row][col] = newVal
                                            appState.calculatorState.matrices[selectedMatrix] = m
                                        }
                                    }
                                ), format: .number)
                                .frame(width: 60, height: 24)
                                .font(.system(size: 13, design: .monospaced))
                                .textFieldStyle(.plain)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.trailing)
                                .border(Color.black.opacity(0.3), width: 0.5)
                            }
                        }
                    }
                }
                .padding(4)
            }

            Spacer()
        }
        .padding(.top, 4)
        .onAppear {
            if let m = appState.calculatorState.matrices[selectedMatrix] {
                rows = m.count
                cols = m.first?.count ?? 0
            }
        }
    }

    private var emptyMatrix: [[Double]] {
        Array(repeating: Array(repeating: 0.0, count: cols), count: rows)
    }

    private func applyDimensions() {
        let clamped_rows = max(1, min(rows, 99))
        let clamped_cols = max(1, min(cols, 99))
        var matrix = appState.calculatorState.matrices[selectedMatrix] ?? []

        // Resize
        while matrix.count < clamped_rows {
            matrix.append(Array(repeating: 0.0, count: clamped_cols))
        }
        while matrix.count > clamped_rows {
            matrix.removeLast()
        }
        for i in 0..<matrix.count {
            while matrix[i].count < clamped_cols { matrix[i].append(0.0) }
            while matrix[i].count > clamped_cols { matrix[i].removeLast() }
        }

        appState.calculatorState.matrices[selectedMatrix] = matrix
        rows = clamped_rows
        cols = clamped_cols
    }
}
