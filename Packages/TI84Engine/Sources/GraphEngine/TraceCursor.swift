import Foundation
import TI84Core

/// Manages the trace cursor on the graph screen.
public class TraceCursor: ObservableObject {
    @Published public var isActive: Bool = false
    @Published public var currentX: Double = 0
    @Published public var currentY: Double = 0
    @Published public var currentFunctionIndex: Int = 0

    private var evaluators: [(Double) -> Double?] = []
    private var enabledIndices: [Int] = []
    private var window: WindowParameters = .standard

    public init() {}

    public func activate(
        evaluators: [(Double) -> Double?],
        enabledIndices: [Int],
        window: WindowParameters
    ) {
        self.evaluators = evaluators
        self.enabledIndices = enabledIndices
        self.window = window
        self.isActive = true
        self.currentFunctionIndex = 0

        // Start at center of window
        self.currentX = (window.xMin + window.xMax) / 2.0
        updateY()
    }

    public func deactivate() {
        isActive = false
    }

    /// Move trace cursor left/right by one pixel step.
    public func moveLeft(pixelWidth: Int) {
        let step = (window.xMax - window.xMin) / Double(pixelWidth)
        currentX -= step
        if currentX < window.xMin { currentX = window.xMin }
        updateY()
    }

    public func moveRight(pixelWidth: Int) {
        let step = (window.xMax - window.xMin) / Double(pixelWidth)
        currentX += step
        if currentX > window.xMax { currentX = window.xMax }
        updateY()
    }

    /// Switch to next/previous function.
    public func moveUp() {
        guard !enabledIndices.isEmpty else { return }
        if let currentPos = enabledIndices.firstIndex(of: currentFunctionIndex) {
            let nextPos = (currentPos + 1) % enabledIndices.count
            currentFunctionIndex = enabledIndices[nextPos]
        }
        updateY()
    }

    public func moveDown() {
        guard !enabledIndices.isEmpty else { return }
        if let currentPos = enabledIndices.firstIndex(of: currentFunctionIndex) {
            let nextPos = (currentPos - 1 + enabledIndices.count) % enabledIndices.count
            currentFunctionIndex = enabledIndices[nextPos]
        }
        updateY()
    }

    /// Set trace to a specific X value (for value/calculate operations).
    public func setX(_ x: Double) {
        currentX = x
        updateY()
    }

    private func updateY() {
        guard currentFunctionIndex < evaluators.count else {
            currentY = 0
            return
        }
        if let y = evaluators[currentFunctionIndex](currentX) {
            currentY = y
        }
    }
}
