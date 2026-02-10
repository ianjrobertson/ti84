import Foundation
import TI84Core

/// Statistics calculations matching TI-84 STAT CALC operations.
public struct StatisticsEngine {
    /// Results from 1-Var Stats
    public struct OneVarResult: Sendable {
        public let mean: Double       // x̄
        public let sum: Double        // Σx
        public let sumSq: Double      // Σx²
        public let stdDevS: Double    // Sx (sample)
        public let stdDevP: Double    // σx (population)
        public let n: Int
        public let minX: Double
        public let q1: Double
        public let median: Double
        public let q3: Double
        public let maxX: Double
    }

    /// Results from 2-Var Stats
    public struct TwoVarResult: Sendable {
        public let meanX: Double
        public let meanY: Double
        public let sumX: Double
        public let sumY: Double
        public let sumXSq: Double
        public let sumYSq: Double
        public let sumXY: Double
        public let stdDevSX: Double
        public let stdDevSY: Double
        public let stdDevPX: Double
        public let stdDevPY: Double
        public let n: Int
        public let minX: Double
        public let maxX: Double
        public let minY: Double
        public let maxY: Double
    }

    /// Regression result
    public struct RegressionResult: Sendable {
        public let equation: String
        public let coefficients: [String: Double]
        public let r: Double?        // Correlation coefficient
        public let rSquared: Double? // R²
    }

    // MARK: - 1-Var Stats

    public static func oneVarStats(_ data: [Double]) throws -> OneVarResult {
        guard !data.isEmpty else { throw CalcError.stat }
        let n = data.count
        let sorted = data.sorted()

        let sum = data.reduce(0, +)
        let mean = sum / Double(n)
        let sumSq = data.reduce(0) { $0 + $1 * $1 }

        let variance = data.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        let stdDevP = sqrt(variance / Double(n))
        let stdDevS = n > 1 ? sqrt(variance / Double(n - 1)) : 0

        return OneVarResult(
            mean: mean,
            sum: sum,
            sumSq: sumSq,
            stdDevS: stdDevS,
            stdDevP: stdDevP,
            n: n,
            minX: sorted.first!,
            q1: quartile(sorted, q: 0.25),
            median: quartile(sorted, q: 0.5),
            q3: quartile(sorted, q: 0.75),
            maxX: sorted.last!
        )
    }

    // MARK: - 2-Var Stats

    public static func twoVarStats(_ xData: [Double], _ yData: [Double]) throws -> TwoVarResult {
        guard xData.count == yData.count, !xData.isEmpty else { throw CalcError.stat }
        let n = xData.count

        let sumX = xData.reduce(0, +)
        let sumY = yData.reduce(0, +)
        let meanX = sumX / Double(n)
        let meanY = sumY / Double(n)
        let sumXSq = xData.reduce(0) { $0 + $1 * $1 }
        let sumYSq = yData.reduce(0) { $0 + $1 * $1 }
        let sumXY = zip(xData, yData).reduce(0) { $0 + $1.0 * $1.1 }

        let varX = xData.reduce(0) { $0 + ($1 - meanX) * ($1 - meanX) }
        let varY = yData.reduce(0) { $0 + ($1 - meanY) * ($1 - meanY) }

        return TwoVarResult(
            meanX: meanX, meanY: meanY,
            sumX: sumX, sumY: sumY,
            sumXSq: sumXSq, sumYSq: sumYSq, sumXY: sumXY,
            stdDevSX: n > 1 ? sqrt(varX / Double(n - 1)) : 0,
            stdDevSY: n > 1 ? sqrt(varY / Double(n - 1)) : 0,
            stdDevPX: sqrt(varX / Double(n)),
            stdDevPY: sqrt(varY / Double(n)),
            n: n,
            minX: xData.min()!, maxX: xData.max()!,
            minY: yData.min()!, maxY: yData.max()!
        )
    }

    // MARK: - Regressions

    /// Linear regression: y = ax + b
    public static func linearRegression(_ xData: [Double], _ yData: [Double]) throws -> RegressionResult {
        guard xData.count == yData.count, xData.count >= 2 else { throw CalcError.stat }
        let n = Double(xData.count)

        let sumX = xData.reduce(0, +)
        let sumY = yData.reduce(0, +)
        let sumXY = zip(xData, yData).reduce(0) { $0 + $1.0 * $1.1 }
        let sumX2 = xData.reduce(0) { $0 + $1 * $1 }

        let denom = n * sumX2 - sumX * sumX
        guard abs(denom) > 1e-14 else { throw CalcError.stat }

        let a = (n * sumXY - sumX * sumY) / denom
        let b = (sumY - a * sumX) / n

        // Correlation
        let sumY2 = yData.reduce(0) { $0 + $1 * $1 }
        let rNum = n * sumXY - sumX * sumY
        let rDenom = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        let r = abs(rDenom) > 1e-14 ? rNum / rDenom : 0

        return RegressionResult(
            equation: "y=ax+b",
            coefficients: ["a": a, "b": b],
            r: r,
            rSquared: r * r
        )
    }

    /// Quadratic regression: y = ax² + bx + c
    public static func quadraticRegression(_ xData: [Double], _ yData: [Double]) throws -> RegressionResult {
        guard xData.count == yData.count, xData.count >= 3 else { throw CalcError.stat }

        // Solve using normal equations: (XᵀX)β = Xᵀy
        let n = xData.count
        var X = Array(repeating: Array(repeating: 0.0, count: 3), count: n)
        for i in 0..<n {
            X[i][0] = xData[i] * xData[i]
            X[i][1] = xData[i]
            X[i][2] = 1.0
        }

        let Xt = MatrixOperations.transpose(X)
        let XtX = matMul(Xt, X)
        let Xty = matVecMul(Xt, yData)

        let coeffs = try solveLinearSystem(XtX, Xty)

        let rSq = rSquared(yData, predicted: xData.map { coeffs[0] * $0 * $0 + coeffs[1] * $0 + coeffs[2] })

        return RegressionResult(
            equation: "y=ax²+bx+c",
            coefficients: ["a": coeffs[0], "b": coeffs[1], "c": coeffs[2]],
            r: nil,
            rSquared: rSq
        )
    }

    /// Exponential regression: y = ab^x
    public static func exponentialRegression(_ xData: [Double], _ yData: [Double]) throws -> RegressionResult {
        guard yData.allSatisfy({ $0 > 0 }) else { throw CalcError.domain }
        let lnY = yData.map { log($0) }
        let linResult = try linearRegression(xData, lnY)
        let lnA = linResult.coefficients["b"]!
        let lnB = linResult.coefficients["a"]!
        return RegressionResult(
            equation: "y=ab^x",
            coefficients: ["a": exp(lnA), "b": exp(lnB)],
            r: linResult.r,
            rSquared: linResult.rSquared
        )
    }

    /// Power regression: y = ax^b
    public static func powerRegression(_ xData: [Double], _ yData: [Double]) throws -> RegressionResult {
        guard xData.allSatisfy({ $0 > 0 }), yData.allSatisfy({ $0 > 0 }) else {
            throw CalcError.domain
        }
        let lnX = xData.map { log($0) }
        let lnY = yData.map { log($0) }
        let linResult = try linearRegression(lnX, lnY)
        let lnA = linResult.coefficients["b"]!
        let b = linResult.coefficients["a"]!
        return RegressionResult(
            equation: "y=ax^b",
            coefficients: ["a": exp(lnA), "b": b],
            r: linResult.r,
            rSquared: linResult.rSquared
        )
    }

    /// Logarithmic regression: y = a + b*ln(x)
    public static func lnRegression(_ xData: [Double], _ yData: [Double]) throws -> RegressionResult {
        guard xData.allSatisfy({ $0 > 0 }) else { throw CalcError.domain }
        let lnX = xData.map { log($0) }
        let linResult = try linearRegression(lnX, yData)
        return RegressionResult(
            equation: "y=a+b*ln(x)",
            coefficients: ["a": linResult.coefficients["b"]!, "b": linResult.coefficients["a"]!],
            r: linResult.r,
            rSquared: linResult.rSquared
        )
    }

    // MARK: - Helpers

    private static func quartile(_ sorted: [Double], q: Double) -> Double {
        let n = sorted.count
        if n == 1 { return sorted[0] }
        let pos = q * Double(n - 1)
        let lower = Int(floor(pos))
        let upper = min(lower + 1, n - 1)
        let frac = pos - Double(lower)
        return sorted[lower] * (1 - frac) + sorted[upper] * frac
    }

    private static func matMul(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        let m = a.count, n = b[0].count, k = b.count
        var result = Array(repeating: Array(repeating: 0.0, count: n), count: m)
        for i in 0..<m {
            for j in 0..<n {
                for p in 0..<k {
                    result[i][j] += a[i][p] * b[p][j]
                }
            }
        }
        return result
    }

    private static func matVecMul(_ a: [[Double]], _ v: [Double]) -> [Double] {
        a.map { row in zip(row, v).reduce(0) { $0 + $1.0 * $1.1 } }
    }

    private static func solveLinearSystem(_ A: [[Double]], _ b: [Double]) throws -> [Double] {
        let n = A.count
        var aug = A.enumerated().map { (i, row) -> [Double] in
            var r = row
            r.append(b[i])
            return r
        }

        for col in 0..<n {
            var maxRow = col
            for row in (col+1)..<n {
                if abs(aug[row][col]) > abs(aug[maxRow][col]) { maxRow = row }
            }
            if abs(aug[maxRow][col]) < 1e-14 { throw CalcError.singular }
            aug.swapAt(col, maxRow)

            let pivot = aug[col][col]
            for j in 0...(n) { aug[col][j] /= pivot }

            for row in 0..<n where row != col {
                let factor = aug[row][col]
                for j in 0...(n) { aug[row][j] -= factor * aug[col][j] }
            }
        }

        return aug.map { $0[n] }
    }

    private static func rSquared(_ actual: [Double], predicted: [Double]) -> Double {
        let mean = actual.reduce(0, +) / Double(actual.count)
        let ssTot = actual.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        let ssRes = zip(actual, predicted).reduce(0) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }
        guard ssTot > 0 else { return 1 }
        return 1 - ssRes / ssTot
    }
}
