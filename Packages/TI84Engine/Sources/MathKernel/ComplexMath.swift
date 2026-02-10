import Foundation
import TI84Core

/// Complex number operations for the TI-84.
public struct ComplexMath {
    public static func add(_ a: (Double, Double), _ b: (Double, Double)) -> (Double, Double) {
        (a.0 + b.0, a.1 + b.1)
    }

    public static func subtract(_ a: (Double, Double), _ b: (Double, Double)) -> (Double, Double) {
        (a.0 - b.0, a.1 - b.1)
    }

    public static func multiply(_ a: (Double, Double), _ b: (Double, Double)) -> (Double, Double) {
        (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0)
    }

    public static func divide(_ a: (Double, Double), _ b: (Double, Double)) throws -> (Double, Double) {
        let denom = b.0 * b.0 + b.1 * b.1
        guard denom != 0 else { throw CalcError.divideByZero }
        return ((a.0 * b.0 + a.1 * b.1) / denom,
                (a.1 * b.0 - a.0 * b.1) / denom)
    }

    public static func magnitude(_ z: (Double, Double)) -> Double {
        Foundation.sqrt(z.0 * z.0 + z.1 * z.1)
    }

    public static func angle(_ z: (Double, Double)) -> Double {
        atan2(z.1, z.0)
    }

    public static func conjugate(_ z: (Double, Double)) -> (Double, Double) {
        (z.0, -z.1)
    }

    public static func power(_ z: (Double, Double), _ n: Double) -> (Double, Double) {
        let r = magnitude(z)
        let theta = angle(z)
        let newR = pow(r, n)
        let newTheta = theta * n
        return (newR * cos(newTheta), newR * sin(newTheta))
    }

    public static func exp(_ z: (Double, Double)) -> (Double, Double) {
        let r = Foundation.exp(z.0)
        return (r * cos(z.1), r * sin(z.1))
    }

    public static func ln(_ z: (Double, Double)) throws -> (Double, Double) {
        let r = magnitude(z)
        guard r > 0 else { throw CalcError.domain }
        return (Foundation.log(r), angle(z))
    }

    public static func sqrt(_ z: (Double, Double)) -> (Double, Double) {
        let r = magnitude(z)
        let theta = angle(z)
        let newR = Foundation.sqrt(r)
        return (newR * cos(theta / 2), newR * sin(theta / 2))
    }
}
