import Foundation
import TI84Core

/// Dispatches built-in function calls to their implementations.
public class FunctionEvaluator {
    public init() {}

    public func evaluate(_ fn: BuiltinFunction, args: [TI84Value], context: EvaluationContext?) throws -> TI84Value {
        // Handle list-argument functions first
        switch fn {
        case .dim:
            return try evalDim(args)
        case .sum:
            return try evalSum(args)
        case .prod:
            return try evalProd(args)
        case .mean:
            return try evalMean(args)
        case .median:
            return try evalMedian(args)
        case .cumSum:
            return try evalCumSum(args)
        case .seq:
            return try evalSeq(args, context: context)
        case .augment:
            return try evalAugment(args)
        case .min:
            return try evalMinMax(args, isMin: true)
        case .max:
            return try evalMinMax(args, isMin: false)
        case .length:
            return try evalLength(args)
        case .sub:
            return try evalSub(args)
        case .inString:
            return try evalInString(args)
        case .det:
            return try evalDet(args)
        case .identity:
            return try evalIdentity(args)
        case .ref:
            return try evalRef(args, reduced: false)
        case .rref:
            return try evalRef(args, reduced: true)
        case .randInt:
            return try evalRandInt(args)
        case .randNorm:
            return try evalRandNorm(args)
        case .rand:
            return .real(Double.random(in: 0..<1))
        case .randM:
            return try evalRandM(args)
        default:
            break
        }

        // Single-argument real functions with list broadcasting
        guard let arg = args.first else { throw CalcError.argument }

        // Handle list broadcasting
        if case .list(let list) = arg {
            let results = try list.map { try evalRealFunction(fn, $0, args: args, context: context) }
            return .list(results)
        }

        guard let x = arg.asReal else { throw CalcError.dataType }
        let result = try evalRealFunction(fn, x, args: args, context: context)
        return .real(result)
    }

    // MARK: - Real Function Evaluation

    private func evalRealFunction(_ fn: BuiltinFunction, _ x: Double, args: [TI84Value], context: EvaluationContext?) throws -> Double {
        let angleMode = context?.modeSettings.angleUnit ?? .radian

        switch fn {
        case .sin:
            return Foundation.sin(toRadians(x, mode: angleMode))
        case .cos:
            return Foundation.cos(toRadians(x, mode: angleMode))
        case .tan:
            let rad = toRadians(x, mode: angleMode)
            let cosVal = Foundation.cos(rad)
            guard abs(cosVal) > 1e-14 else { throw CalcError.domain }
            return Foundation.sin(rad) / cosVal
        case .asin:
            guard x >= -1 && x <= 1 else { throw CalcError.domain }
            return fromRadians(Foundation.asin(x), mode: angleMode)
        case .acos:
            guard x >= -1 && x <= 1 else { throw CalcError.domain }
            return fromRadians(Foundation.acos(x), mode: angleMode)
        case .atan:
            return fromRadians(Foundation.atan(x), mode: angleMode)
        case .sinh:
            return Foundation.sinh(x)
        case .cosh:
            return Foundation.cosh(x)
        case .tanh:
            return Foundation.tanh(x)
        case .asinh:
            return Foundation.asinh(x)
        case .acosh:
            guard x >= 1 else { throw CalcError.domain }
            return Foundation.acosh(x)
        case .atanh:
            guard x > -1 && x < 1 else { throw CalcError.domain }
            return Foundation.atanh(x)
        case .sqrt:
            guard x >= 0 else { throw CalcError.nonReal }
            return Foundation.sqrt(x)
        case .cbrt:
            return cbrt(x)
        case .log:
            guard x > 0 else { throw CalcError.domain }
            if args.count >= 2, let base = args[1].asReal {
                guard base > 0, base != 1 else { throw CalcError.domain }
                return Foundation.log(x) / Foundation.log(base)
            }
            return log10(x)
        case .ln:
            guard x > 0 else { throw CalcError.domain }
            return Foundation.log(x)
        case .tenPow:
            let result = pow(10.0, x)
            guard result.isFinite else { throw CalcError.overflow }
            return result
        case .ePow:
            let result = exp(x)
            guard result.isFinite else { throw CalcError.overflow }
            return result
        case .abs:
            return Swift.abs(x)
        case .round:
            if args.count >= 2, let places = args[1].asInt {
                let multiplier = pow(10.0, Double(places))
                return (x * multiplier).rounded() / multiplier
            }
            return (x * 1e10).rounded() / 1e10 // Default: 10 decimal places
        case .iPart:
            return x >= 0 ? floor(x) : ceil(x)
        case .fPart:
            return x - (x >= 0 ? floor(x) : ceil(x))
        case .int_:
            return floor(x) // int( always floors toward negative infinity
        case .lcm:
            guard args.count >= 2, let b = args[1].asReal else { throw CalcError.argument }
            let ia = Int(abs(x)), ib = Int(abs(b))
            guard ia > 0 && ib > 0 else { return 0 }
            return Double(ia / gcd(ia, ib) * ib)
        case .gcd:
            guard args.count >= 2, let b = args[1].asReal else { throw CalcError.argument }
            return Double(gcd(Int(abs(x)), Int(abs(b))))
        case .nDeriv:
            // nDeriv(expr, X, value) — needs special handling
            // For now, return numerical derivative
            return try numericalDerivative(args: args, context: context)
        case .fnInt:
            return try numericalIntegral(args: args, context: context)
        case .normalPdf:
            return try normalPdf(x, args: args)
        case .normalCdf:
            return try normalCdf(args: args)
        case .invNorm:
            return try invNorm(x, args: args)
        case .binomPdf:
            return try binomPdf(args: args)
        case .binomCdf:
            return try binomCdf(args: args)
        default:
            throw CalcError.syntax
        }
    }

    // MARK: - Angle Conversion

    private func toRadians(_ value: Double, mode: ModeSettings.AngleUnit) -> Double {
        switch mode {
        case .radian: return value
        case .degree: return value * .pi / 180.0
        }
    }

    private func fromRadians(_ value: Double, mode: ModeSettings.AngleUnit) -> Double {
        switch mode {
        case .radian: return value
        case .degree: return value * 180.0 / .pi
        }
    }

    // MARK: - List Functions

    private func evalDim(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first else { throw CalcError.argument }
        switch arg {
        case .list(let l): return .real(Double(l.count))
        case .matrix(let m): return .list([Double(m.count), Double(m[0].count)])
        default: throw CalcError.dataType
        }
    }

    private func evalSum(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first, let list = arg.asList else { throw CalcError.dataType }
        if args.count >= 3, let start = args[1].asInt, let end = args[2].asInt {
            guard start >= 1 && end <= list.count && start <= end else { throw CalcError.invalidDim }
            return .real(list[(start-1)..<end].reduce(0, +))
        }
        return .real(list.reduce(0, +))
    }

    private func evalProd(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first, let list = arg.asList else { throw CalcError.dataType }
        return .real(list.reduce(1, *))
    }

    private func evalMean(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first, let list = arg.asList, !list.isEmpty else { throw CalcError.dataType }
        return .real(list.reduce(0, +) / Double(list.count))
    }

    private func evalMedian(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first, let list = arg.asList, !list.isEmpty else { throw CalcError.dataType }
        let sorted = list.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return .real((sorted[mid - 1] + sorted[mid]) / 2.0)
        }
        return .real(sorted[mid])
    }

    private func evalCumSum(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first, let list = arg.asList else { throw CalcError.dataType }
        var running = 0.0
        let result = list.map { val -> Double in
            running += val
            return running
        }
        return .list(result)
    }

    private func evalSeq(_ args: [TI84Value], context: EvaluationContext?) throws -> TI84Value {
        // seq(expr, var, start, end[, step])
        // Simplified: seq works with the expression string and variable name
        guard args.count >= 4 else { throw CalcError.argument }
        guard let start = args[2].asReal, let end = args[3].asReal else { throw CalcError.dataType }
        let step = args.count >= 5 ? (args[4].asReal ?? 1) : 1

        // The first arg should be an expression evaluated with the variable
        // For now, generate the sequence based on start/end/step
        var result: [Double] = []
        var x = start
        while (step > 0 && x <= end) || (step < 0 && x >= end) {
            result.append(x)
            x += step
        }
        return .list(result)
    }

    private func evalAugment(_ args: [TI84Value]) throws -> TI84Value {
        guard args.count >= 2 else { throw CalcError.argument }
        if let l1 = args[0].asList, let l2 = args[1].asList {
            return .list(l1 + l2)
        }
        if let m1 = args[0].asMatrix, let m2 = args[1].asMatrix {
            guard m1.count == m2.count else { throw CalcError.dimensionMismatch }
            return .matrix(zip(m1, m2).map { $0 + $1 })
        }
        throw CalcError.dataType
    }

    private func evalMinMax(_ args: [TI84Value], isMin: Bool) throws -> TI84Value {
        if args.count >= 2 {
            guard let a = args[0].asReal, let b = args[1].asReal else { throw CalcError.dataType }
            return .real(isMin ? Swift.min(a, b) : Swift.max(a, b))
        }
        guard let arg = args.first, let list = arg.asList, !list.isEmpty else { throw CalcError.dataType }
        return .real(isMin ? list.min()! : list.max()!)
    }

    // MARK: - String Functions

    private func evalLength(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first else { throw CalcError.argument }
        if case .string(let s) = arg { return .real(Double(s.count)) }
        if case .list(let l) = arg { return .real(Double(l.count)) }
        throw CalcError.dataType
    }

    private func evalSub(_ args: [TI84Value]) throws -> TI84Value {
        guard args.count >= 3 else { throw CalcError.argument }
        guard case .string(let str) = args[0],
              let start = args[1].asInt,
              let length = args[2].asInt else { throw CalcError.dataType }
        guard start >= 1, start + length - 1 <= str.count else { throw CalcError.invalidDim }
        let startIdx = str.index(str.startIndex, offsetBy: start - 1)
        let endIdx = str.index(startIdx, offsetBy: length)
        return .string(String(str[startIdx..<endIdx]))
    }

    private func evalInString(_ args: [TI84Value]) throws -> TI84Value {
        guard args.count >= 2 else { throw CalcError.argument }
        guard case .string(let haystack) = args[0],
              case .string(let needle) = args[1] else { throw CalcError.dataType }
        let start = args.count >= 3 ? (args[2].asInt ?? 1) : 1
        guard start >= 1 else { throw CalcError.invalidDim }
        let searchStart = haystack.index(haystack.startIndex, offsetBy: start - 1)
        if let range = haystack[searchStart...].range(of: needle) {
            return .real(Double(haystack.distance(from: haystack.startIndex, to: range.lowerBound) + 1))
        }
        return .real(0)
    }

    // MARK: - Matrix Functions

    private func evalDet(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first, let matrix = arg.asMatrix else { throw CalcError.dataType }
        guard matrix.count == matrix[0].count else { throw CalcError.dimensionMismatch }
        return .real(determinant(matrix))
    }

    private func determinant(_ m: [[Double]]) -> Double {
        let n = m.count
        if n == 1 { return m[0][0] }
        if n == 2 { return m[0][0] * m[1][1] - m[0][1] * m[1][0] }

        var result = 0.0
        for j in 0..<n {
            var minor = m
            minor.remove(at: 0)
            for i in 0..<minor.count {
                minor[i].remove(at: j)
            }
            let sign = (j % 2 == 0) ? 1.0 : -1.0
            result += sign * m[0][j] * determinant(minor)
        }
        return result
    }

    private func evalIdentity(_ args: [TI84Value]) throws -> TI84Value {
        guard let arg = args.first, let n = arg.asInt, n >= 1 else { throw CalcError.argument }
        var matrix = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        for i in 0..<n { matrix[i][i] = 1.0 }
        return .matrix(matrix)
    }

    private func evalRef(_ args: [TI84Value], reduced: Bool) throws -> TI84Value {
        guard let arg = args.first, var matrix = arg.asMatrix else { throw CalcError.dataType }
        let rows = matrix.count
        let cols = matrix[0].count
        var pivotRow = 0

        for col in 0..<cols {
            guard pivotRow < rows else { break }

            // Find pivot
            var maxRow = pivotRow
            for row in (pivotRow + 1)..<rows {
                if abs(matrix[row][col]) > abs(matrix[maxRow][col]) {
                    maxRow = row
                }
            }

            if abs(matrix[maxRow][col]) < 1e-14 { continue }

            // Swap rows
            if maxRow != pivotRow {
                matrix.swapAt(pivotRow, maxRow)
            }

            // Scale pivot row
            let scale = matrix[pivotRow][col]
            for j in 0..<cols {
                matrix[pivotRow][j] /= scale
            }

            // Eliminate
            let startRow = reduced ? 0 : pivotRow + 1
            for row in startRow..<rows {
                if row == pivotRow { continue }
                let factor = matrix[row][col]
                for j in 0..<cols {
                    matrix[row][j] -= factor * matrix[pivotRow][j]
                }
            }

            pivotRow += 1
        }

        return .matrix(matrix)
    }

    private func evalRandInt(_ args: [TI84Value]) throws -> TI84Value {
        guard args.count >= 2,
              let lo = args[0].asInt,
              let hi = args[1].asInt,
              lo <= hi else { throw CalcError.argument }
        if args.count >= 3, let n = args[2].asInt {
            let list = (0..<n).map { _ in Double(Int.random(in: lo...hi)) }
            return .list(list)
        }
        return .real(Double(Int.random(in: lo...hi)))
    }

    private func evalRandNorm(_ args: [TI84Value]) throws -> TI84Value {
        guard args.count >= 2,
              let mu = args[0].asReal,
              let sigma = args[1].asReal else { throw CalcError.argument }
        // Box-Muller transform
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        let z = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return .real(mu + sigma * z)
    }

    private func evalRandM(_ args: [TI84Value]) throws -> TI84Value {
        guard args.count >= 2,
              let rows = args[0].asInt,
              let cols = args[1].asInt,
              rows >= 1, cols >= 1 else { throw CalcError.argument }
        let matrix = (0..<rows).map { _ in
            (0..<cols).map { _ in Double(Int.random(in: -9...9)) }
        }
        return .matrix(matrix)
    }

    // MARK: - Numerical Calculus

    private func numericalDerivative(args: [TI84Value], context: EvaluationContext?) throws -> Double {
        // nDeriv needs special handling with expression evaluation
        // Simplified: expects numeric args for now
        guard args.count >= 1, let x = args[0].asReal else { throw CalcError.argument }
        return x // placeholder
    }

    private func numericalIntegral(args: [TI84Value], context: EvaluationContext?) throws -> Double {
        guard args.count >= 1, let x = args[0].asReal else { throw CalcError.argument }
        return x // placeholder
    }

    // MARK: - Statistics Functions

    private func normalPdf(_ x: Double, args: [TI84Value]) throws -> Double {
        let mu = args.count >= 2 ? (args[1].asReal ?? 0) : 0
        let sigma = args.count >= 3 ? (args[2].asReal ?? 1) : 1
        guard sigma > 0 else { throw CalcError.domain }
        let z = (x - mu) / sigma
        return exp(-0.5 * z * z) / (sigma * sqrt(2.0 * .pi))
    }

    private func normalCdf(args: [TI84Value]) throws -> Double {
        guard args.count >= 2,
              let lo = args[0].asReal,
              let hi = args[1].asReal else { throw CalcError.argument }
        let mu = args.count >= 3 ? (args[2].asReal ?? 0) : 0
        let sigma = args.count >= 4 ? (args[3].asReal ?? 1) : 1
        guard sigma > 0 else { throw CalcError.domain }
        return normalCdfValue((hi - mu) / sigma) - normalCdfValue((lo - mu) / sigma)
    }

    private func normalCdfValue(_ x: Double) -> Double {
        // Approximation of standard normal CDF using error function
        return 0.5 * (1.0 + erf(x / sqrt(2.0)))
    }

    private func invNorm(_ p: Double, args: [TI84Value]) throws -> Double {
        guard p > 0, p < 1 else { throw CalcError.domain }
        let mu = args.count >= 2 ? (args[1].asReal ?? 0) : 0
        let sigma = args.count >= 3 ? (args[2].asReal ?? 1) : 1
        guard sigma > 0 else { throw CalcError.domain }

        // Rational approximation of inverse normal
        let a = [
            -3.969683028665376e+01, 2.209460984245205e+02,
            -2.759285104469687e+02, 1.383577518672690e+02,
            -3.066479806614716e+01, 2.506628277459239e+00
        ]
        let b = [
            -5.447609879822406e+01, 1.615858368580409e+02,
            -1.556989798598866e+02, 6.680131188771972e+01,
            -1.328068155288572e+01
        ]

        let pLow = 0.02425
        let pHigh = 1.0 - pLow
        var z: Double

        if p < pLow {
            let q = sqrt(-2.0 * log(p))
            z = (((((a[0]*q+a[1])*q+a[2])*q+a[3])*q+a[4])*q+a[5]) /
                ((((b[0]*q+b[1])*q+b[2])*q+b[3])*q+b[4]*q+1.0)
        } else if p <= pHigh {
            let q = p - 0.5
            let r = q * q
            z = (((((a[0]*r+a[1])*r+a[2])*r+a[3])*r+a[4])*r+a[5])*q /
                (((((b[0]*r+b[1])*r+b[2])*r+b[3])*r+b[4])*r+1.0)
        } else {
            let q = sqrt(-2.0 * log(1.0 - p))
            z = -(((((a[0]*q+a[1])*q+a[2])*q+a[3])*q+a[4])*q+a[5]) /
                ((((b[0]*q+b[1])*q+b[2])*q+b[3])*q+b[4]*q+1.0)
        }

        return mu + sigma * z
    }

    private func binomPdf(args: [TI84Value]) throws -> Double {
        guard args.count >= 3,
              let n = args[0].asInt, n >= 0,
              let p = args[1].asReal, p >= 0, p <= 1,
              let k = args[2].asInt, k >= 0, k <= n else { throw CalcError.argument }
        let coeff = try combination(n, k)
        return coeff * pow(p, Double(k)) * pow(1 - p, Double(n - k))
    }

    private func binomCdf(args: [TI84Value]) throws -> Double {
        guard args.count >= 3,
              let n = args[0].asInt, n >= 0,
              let p = args[1].asReal, p >= 0, p <= 1,
              let k = args[2].asInt, k >= 0 else { throw CalcError.argument }
        var sum = 0.0
        for i in 0...Swift.min(k, n) {
            let coeff = try combination(n, i)
            sum += coeff * pow(p, Double(i)) * pow(1 - p, Double(n - i))
        }
        return sum
    }

    private func combination(_ n: Int, _ r: Int) throws -> Double {
        guard n >= 0, r >= 0, r <= n else { throw CalcError.domain }
        if r == 0 || r == n { return 1 }
        let r = Swift.min(r, n - r)
        var result = 1.0
        for i in 0..<r {
            result *= Double(n - i) / Double(i + 1)
        }
        return result
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 {
            let t = b
            b = a % b
            a = t
        }
        return a
    }
}
