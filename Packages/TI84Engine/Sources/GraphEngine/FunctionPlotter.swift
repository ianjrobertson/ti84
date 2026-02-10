import Foundation
import TI84Core

/// Generates plot points for a mathematical function within a window.
public struct FunctionPlotter {
    /// A point in graph coordinates (mathematical space).
    public struct PlotPoint: Sendable {
        public let x: Double
        public let y: Double
        public let isDiscontinuity: Bool

        public init(x: Double, y: Double, isDiscontinuity: Bool = false) {
            self.x = x
            self.y = y
            self.isDiscontinuity = isDiscontinuity
        }
    }

    /// A connected segment of plot points (break at discontinuities).
    public struct PlotSegment: Sendable {
        public let points: [PlotPoint]

        public init(points: [PlotPoint]) {
            self.points = points
        }
    }

    /// Plot a function within the given window parameters.
    /// - Parameters:
    ///   - evaluator: Closure that evaluates y = f(x)
    ///   - window: Window parameters defining the visible region
    ///   - pixelWidth: Width of the view in pixels
    /// - Returns: Array of connected segments
    public static func plot(
        evaluator: (Double) -> Double?,
        window: WindowParameters,
        pixelWidth: Int
    ) -> [PlotSegment] {
        let xRange = window.xMax - window.xMin
        let numSamples = pixelWidth / window.xRes
        let step = xRange / Double(numSamples)

        var segments: [PlotSegment] = []
        var currentPoints: [PlotPoint] = []
        var lastY: Double? = nil

        for i in 0...numSamples {
            let x = window.xMin + Double(i) * step
            guard let y = evaluator(x), y.isFinite else {
                // Break segment at undefined/infinite point
                if !currentPoints.isEmpty {
                    segments.append(PlotSegment(points: currentPoints))
                    currentPoints = []
                }
                lastY = nil
                continue
            }

            // Check for discontinuity (large jump between consecutive points)
            let isDiscontinuity: Bool
            if let prevY = lastY {
                let yRange = window.yMax - window.yMin
                let jump = abs(y - prevY)
                isDiscontinuity = jump > yRange * 2
            } else {
                isDiscontinuity = false
            }

            if isDiscontinuity {
                if !currentPoints.isEmpty {
                    segments.append(PlotSegment(points: currentPoints))
                    currentPoints = []
                }
            }

            currentPoints.append(PlotPoint(x: x, y: y))
            lastY = y
        }

        if !currentPoints.isEmpty {
            segments.append(PlotSegment(points: currentPoints))
        }

        return segments
    }

    /// Convert a mathematical (x,y) point to view coordinates.
    public static func mathToView(
        x: Double, y: Double,
        window: WindowParameters,
        viewWidth: Double, viewHeight: Double
    ) -> (Double, Double) {
        let vx = (x - window.xMin) / (window.xMax - window.xMin) * viewWidth
        let vy = (1.0 - (y - window.yMin) / (window.yMax - window.yMin)) * viewHeight
        return (vx, vy)
    }

    /// Convert view coordinates back to mathematical coordinates.
    public static func viewToMath(
        vx: Double, vy: Double,
        window: WindowParameters,
        viewWidth: Double, viewHeight: Double
    ) -> (Double, Double) {
        let x = window.xMin + vx / viewWidth * (window.xMax - window.xMin)
        let y = window.yMax - vy / viewHeight * (window.yMax - window.yMin)
        return (x, y)
    }
}
