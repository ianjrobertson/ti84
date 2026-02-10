import Foundation
import TI84Core

/// Finds minimum/maximum of functions using golden section search.
public struct ExtremumFinder {
    private static let phi = (1.0 + sqrt(5.0)) / 2.0
    private static let resphi = 2.0 - phi

    /// Find a minimum of f(x) between leftBound and rightBound.
    public static func findMinimum(
        evaluator: (Double) -> Double?,
        leftBound: Double,
        rightBound: Double,
        tolerance: Double = 1e-10,
        maxIterations: Int = 100
    ) throws -> (x: Double, y: Double) {
        return try goldenSection(evaluator: evaluator, a: leftBound, b: rightBound,
                                 tolerance: tolerance, maxIterations: maxIterations,
                                 findMin: true)
    }

    /// Find a maximum of f(x) between leftBound and rightBound.
    public static func findMaximum(
        evaluator: (Double) -> Double?,
        leftBound: Double,
        rightBound: Double,
        tolerance: Double = 1e-10,
        maxIterations: Int = 100
    ) throws -> (x: Double, y: Double) {
        return try goldenSection(evaluator: evaluator, a: leftBound, b: rightBound,
                                 tolerance: tolerance, maxIterations: maxIterations,
                                 findMin: false)
    }

    /// Find intersection of two functions using bisection on f(x) - g(x).
    public static func findIntersection(
        f: (Double) -> Double?,
        g: (Double) -> Double?,
        leftBound: Double,
        rightBound: Double,
        tolerance: Double = 1e-12
    ) throws -> (x: Double, y: Double) {
        let diff: (Double) -> Double? = { x in
            guard let fy = f(x), let gy = g(x) else { return nil }
            return fy - gy
        }

        let x = try RootFinder.findZero(evaluator: diff, leftBound: leftBound, rightBound: rightBound, tolerance: tolerance)
        guard let y = f(x) else { throw CalcError.domain }
        return (x, y)
    }

    /// Numerical derivative at a point.
    public static func numericalDerivative(
        evaluator: (Double) -> Double?,
        x: Double,
        h: Double = 1e-6
    ) -> Double? {
        guard let yPlus = evaluator(x + h),
              let yMinus = evaluator(x - h) else { return nil }
        return (yPlus - yMinus) / (2.0 * h)
    }

    /// Numerical integral using Simpson's rule.
    public static func numericalIntegral(
        evaluator: (Double) -> Double?,
        a: Double,
        b: Double,
        n: Int = 1000
    ) -> Double? {
        guard n > 0, n % 2 == 0 else { return nil }
        let h = (b - a) / Double(n)
        var sum = 0.0

        guard let fa = evaluator(a), let fb = evaluator(b) else { return nil }
        sum += fa + fb

        for i in 1..<n {
            let x = a + Double(i) * h
            guard let fx = evaluator(x) else { return nil }
            sum += (i % 2 == 0 ? 2 : 4) * fx
        }

        return sum * h / 3.0
    }

    // MARK: - Golden Section Search

    private static func goldenSection(
        evaluator: (Double) -> Double?,
        a: Double, b: Double,
        tolerance: Double,
        maxIterations: Int,
        findMin: Bool
    ) throws -> (x: Double, y: Double) {
        var a = a
        var b = b
        var x1 = a + resphi * (b - a)
        var x2 = b - resphi * (b - a)

        guard var f1 = evaluator(x1), var f2 = evaluator(x2) else {
            throw CalcError.domain
        }

        for _ in 0..<maxIterations {
            if abs(b - a) < tolerance {
                let x = (a + b) / 2.0
                guard let y = evaluator(x) else { throw CalcError.domain }
                return (x, y)
            }

            let compare = findMin ? (f1 < f2) : (f1 > f2)
            if compare {
                b = x2
                x2 = x1
                f2 = f1
                x1 = a + resphi * (b - a)
                guard let newF1 = evaluator(x1) else { throw CalcError.domain }
                f1 = newF1
            } else {
                a = x1
                x1 = x2
                f1 = f2
                x2 = b - resphi * (b - a)
                guard let newF2 = evaluator(x2) else { throw CalcError.domain }
                f2 = newF2
            }
        }

        let x = (a + b) / 2.0
        guard let y = evaluator(x) else { throw CalcError.domain }
        return (x, y)
    }
}
