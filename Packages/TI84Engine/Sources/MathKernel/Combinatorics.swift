import Foundation
import TI84Core

/// Combinatorics and probability functions.
public struct Combinatorics {
    /// Factorial: n!
    public static func factorial(_ n: Int) throws -> Double {
        guard n >= 0 else { throw CalcError.domain }
        guard n <= 69 else { throw CalcError.overflow }
        if n == 0 { return 1 }
        var result = 1.0
        for i in 1...n {
            result *= Double(i)
        }
        return result
    }

    /// Permutation: nPr = n!/(n-r)!
    public static func permutation(_ n: Int, _ r: Int) throws -> Double {
        guard n >= 0, r >= 0, r <= n else { throw CalcError.domain }
        var result = 1.0
        for i in (n - r + 1)...n {
            result *= Double(i)
        }
        return result
    }

    /// Combination: nCr = n!/(r!(n-r)!)
    public static func combination(_ n: Int, _ r: Int) throws -> Double {
        guard n >= 0, r >= 0, r <= n else { throw CalcError.domain }
        let r = Swift.min(r, n - r) // Optimization
        var result = 1.0
        for i in 0..<r {
            result *= Double(n - i) / Double(i + 1)
        }
        return result
    }
}
