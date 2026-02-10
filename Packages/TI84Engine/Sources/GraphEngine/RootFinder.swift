import Foundation
import TI84Core

/// Finds roots (zeros) of functions using bisection method.
public struct RootFinder {
    /// Find a zero of f(x) between leftBound and rightBound using bisection.
    /// Returns the x value where f(x) ≈ 0, or nil if no sign change found.
    public static func findZero(
        evaluator: (Double) -> Double?,
        leftBound: Double,
        rightBound: Double,
        tolerance: Double = 1e-12,
        maxIterations: Int = 100
    ) throws -> Double {
        guard var fLeft = evaluator(leftBound),
              var fRight = evaluator(rightBound) else {
            throw CalcError.domain
        }

        // Check for sign change
        guard fLeft * fRight <= 0 else {
            throw CalcError.iterations
        }

        var a = leftBound
        var b = rightBound

        for _ in 0..<maxIterations {
            let mid = (a + b) / 2.0
            guard let fMid = evaluator(mid) else {
                throw CalcError.domain
            }

            if abs(fMid) < tolerance || (b - a) / 2.0 < tolerance {
                return mid
            }

            if fMid * fLeft > 0 {
                a = mid
                fLeft = fMid
            } else {
                b = mid
                fRight = fMid
            }
        }

        return (a + b) / 2.0
    }
}
