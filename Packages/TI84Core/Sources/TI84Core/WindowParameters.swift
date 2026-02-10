import Foundation

/// Graph window parameters matching the TI-84 WINDOW screen.
public struct WindowParameters: Equatable, Sendable {
    // Function mode
    public var xMin: Double
    public var xMax: Double
    public var xScl: Double
    public var yMin: Double
    public var yMax: Double
    public var yScl: Double
    public var xRes: Int  // 1-8, sampling resolution

    // Parametric mode
    public var tMin: Double
    public var tMax: Double
    public var tStep: Double

    // Polar mode
    public var thetaMin: Double
    public var thetaMax: Double
    public var thetaStep: Double

    // Sequence mode
    public var nMin: Int
    public var nMax: Int
    public var plotStart: Int
    public var plotStep: Int

    /// Standard zoom (-10 to 10)
    public static let standard = WindowParameters()

    public init() {
        xMin = -10
        xMax = 10
        xScl = 1
        yMin = -10
        yMax = 10
        yScl = 1
        xRes = 1
        tMin = 0
        tMax = 2 * .pi
        tStep = .pi / 24
        thetaMin = 0
        thetaMax = 2 * .pi
        thetaStep = .pi / 24
        nMin = 1
        nMax = 10
        plotStart = 1
        plotStep = 1
    }

    /// ZTrig zoom preset
    public static var trig: WindowParameters {
        var w = WindowParameters()
        w.xMin = -(47.0 / 24.0) * .pi
        w.xMax = (47.0 / 24.0) * .pi
        w.xScl = .pi / 2
        w.yMin = -4
        w.yMax = 4
        w.yScl = 1
        return w
    }

    /// ZDecimal zoom preset
    public static var decimal: WindowParameters {
        var w = WindowParameters()
        w.xMin = -4.7
        w.xMax = 4.7
        w.xScl = 1
        w.yMin = -3.1
        w.yMax = 3.1
        w.yScl = 1
        return w
    }

    /// ZInteger zoom preset
    public static var integer: WindowParameters {
        var w = WindowParameters()
        w.xMin = -47
        w.xMax = 47
        w.xScl = 10
        w.yMin = -31
        w.yMax = 31
        w.yScl = 10
        return w
    }

    /// ZSquare: adjusts to make pixels square
    public func squared(viewWidth: Double, viewHeight: Double) -> WindowParameters {
        var w = self
        let xRange = xMax - xMin
        let yRange = yMax - yMin
        let aspect = viewWidth / viewHeight
        let currentAspect = xRange / yRange

        if currentAspect > aspect {
            let newYRange = xRange / aspect
            let yCenter = (yMin + yMax) / 2
            w.yMin = yCenter - newYRange / 2
            w.yMax = yCenter + newYRange / 2
        } else {
            let newXRange = yRange * aspect
            let xCenter = (xMin + xMax) / 2
            w.xMin = xCenter - newXRange / 2
            w.xMax = xCenter + newXRange / 2
        }
        return w
    }
}
