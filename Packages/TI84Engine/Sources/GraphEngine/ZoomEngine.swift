import Foundation
import TI84Core

/// Handles zoom operations on the graph window.
public struct ZoomEngine {
    /// Apply a zoom preset.
    public static func applyPreset(_ preset: ZoomPreset, current: WindowParameters, viewWidth: Double, viewHeight: Double) -> WindowParameters {
        switch preset {
        case .standard:
            return .standard
        case .trig:
            return .trig
        case .decimal:
            return .decimal
        case .integer:
            return .integer
        case .square:
            return current.squared(viewWidth: viewWidth, viewHeight: viewHeight)
        case .zoomIn:
            return zoom(current, factor: 0.25)
        case .zoomOut:
            return zoom(current, factor: 4.0)
        case .zoomFit:
            return current // Handled externally with function evaluation
        case .zoomStat:
            return current // Handled externally with stat data
        case .zoomPrev:
            return current // Handled by maintaining history
        }
    }

    /// Zoom by a factor centered on the current view.
    /// Factor < 1 = zoom in, factor > 1 = zoom out.
    public static func zoom(_ window: WindowParameters, factor: Double) -> WindowParameters {
        var w = window
        let xCenter = (w.xMin + w.xMax) / 2
        let yCenter = (w.yMin + w.yMax) / 2
        let xRange = (w.xMax - w.xMin) * factor
        let yRange = (w.yMax - w.yMin) * factor
        w.xMin = xCenter - xRange / 2
        w.xMax = xCenter + xRange / 2
        w.yMin = yCenter - yRange / 2
        w.yMax = yCenter + yRange / 2
        return w
    }

    /// Zoom centered on a specific point.
    public static func zoomAt(_ window: WindowParameters, center: (Double, Double), factor: Double) -> WindowParameters {
        var w = window
        let xRange = (w.xMax - w.xMin) * factor
        let yRange = (w.yMax - w.yMin) * factor
        w.xMin = center.0 - xRange / 2
        w.xMax = center.0 + xRange / 2
        w.yMin = center.1 - yRange / 2
        w.yMax = center.1 + yRange / 2
        return w
    }

    /// Zoom box: set window to the specified rectangle.
    public static func zoomBox(_ topLeft: (Double, Double), bottomRight: (Double, Double)) -> WindowParameters {
        var w = WindowParameters()
        w.xMin = min(topLeft.0, bottomRight.0)
        w.xMax = max(topLeft.0, bottomRight.0)
        w.yMin = min(topLeft.1, bottomRight.1)
        w.yMax = max(topLeft.1, bottomRight.1)
        return w
    }

    /// ZoomFit: adjust yMin/yMax to fit the plotted functions.
    public static func zoomFit(
        _ window: WindowParameters,
        evaluators: [(Double) -> Double?],
        pixelWidth: Int
    ) -> WindowParameters {
        var w = window
        var minY = Double.infinity
        var maxY = -Double.infinity
        let step = (w.xMax - w.xMin) / Double(pixelWidth)

        for eval in evaluators {
            for i in 0...pixelWidth {
                let x = w.xMin + Double(i) * step
                if let y = eval(x), y.isFinite {
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        if minY < maxY {
            let padding = (maxY - minY) * 0.1
            w.yMin = minY - padding
            w.yMax = maxY + padding
        }

        return w
    }
}

public enum ZoomPreset: String, CaseIterable, Sendable {
    case standard = "ZStandard"
    case trig = "ZTrig"
    case decimal = "ZDecimal"
    case integer = "ZInteger"
    case square = "ZSquare"
    case zoomIn = "Zoom In"
    case zoomOut = "Zoom Out"
    case zoomFit = "ZoomFit"
    case zoomStat = "ZoomStat"
    case zoomPrev = "ZPrevious"
}
