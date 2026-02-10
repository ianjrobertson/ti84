import Foundation
import TI84Core
import TI84Engine

/// ViewModel for the graph screen.
class GraphViewModel: ObservableObject {
    weak var appState: AppState?
    @Published var isTracing: Bool = false
    @Published var traceX: Double = 0
    @Published var traceY: Double = 0
    @Published var traceFunctionIndex: Int = 1

    private var enabledFunctions: [Int] = []
    private let pixelWidth = 380

    init(appState: AppState) {
        self.appState = appState
    }

    func startTrace() {
        guard let state = appState else { return }

        // Find enabled functions
        enabledFunctions = []
        for i in 1...9 {
            if state.calculatorState.isYVarEnabled(i) &&
               !state.calculatorState.yVarExpression(i).isEmpty {
                enabledFunctions.append(i)
            }
        }
        if state.calculatorState.isYVarEnabled(0) &&
           !state.calculatorState.yVarExpression(0).isEmpty {
            enabledFunctions.append(0)
        }

        guard !enabledFunctions.isEmpty else { return }

        isTracing = true
        traceFunctionIndex = enabledFunctions.first ?? 1
        traceX = (state.calculatorState.windowParameters.xMin + state.calculatorState.windowParameters.xMax) / 2
        updateTraceY()
    }

    func traceLeft() {
        guard let state = appState, isTracing else { return }
        let window = state.calculatorState.windowParameters
        let step = (window.xMax - window.xMin) / Double(pixelWidth)
        traceX -= step
        if traceX < window.xMin { traceX = window.xMin }
        updateTraceY()
    }

    func traceRight() {
        guard let state = appState, isTracing else { return }
        let window = state.calculatorState.windowParameters
        let step = (window.xMax - window.xMin) / Double(pixelWidth)
        traceX += step
        if traceX > window.xMax { traceX = window.xMax }
        updateTraceY()
    }

    func traceFunctionUp() {
        guard isTracing, !enabledFunctions.isEmpty else { return }
        if let idx = enabledFunctions.firstIndex(of: traceFunctionIndex) {
            let next = (idx + 1) % enabledFunctions.count
            traceFunctionIndex = enabledFunctions[next]
            updateTraceY()
        }
    }

    func traceFunctionDown() {
        guard isTracing, !enabledFunctions.isEmpty else { return }
        if let idx = enabledFunctions.firstIndex(of: traceFunctionIndex) {
            let next = (idx - 1 + enabledFunctions.count) % enabledFunctions.count
            traceFunctionIndex = enabledFunctions[next]
            updateTraceY()
        }
    }

    private func updateTraceY() {
        guard let state = appState else { return }
        if let y = try? state.calculatorState.evaluateYVar(traceFunctionIndex, x: traceX) {
            traceY = y
        }
    }

    // MARK: - Zoom Operations

    func applyZoom(_ preset: ZoomPreset) {
        guard let state = appState else { return }
        let window = state.calculatorState.windowParameters

        let evaluators: [(Double) -> Double?] = enabledFunctions.map { yNum in
            { [weak state] x in try? state?.calculatorState.evaluateYVar(yNum, x: x) }
        }

        switch preset {
        case .zoomFit:
            state.calculatorState.windowParameters = ZoomEngine.zoomFit(
                window, evaluators: evaluators, pixelWidth: pixelWidth
            )
        default:
            state.calculatorState.windowParameters = ZoomEngine.applyPreset(
                preset, current: window, viewWidth: Double(pixelWidth), viewHeight: 260
            )
        }
    }
}
