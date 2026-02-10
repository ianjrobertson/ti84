import Foundation
import TI84Core

/// Protocol for accessing calculator state during evaluation.
public protocol EvaluationContext: AnyObject {
    var ans: TI84Value { get set }
    var modeSettings: ModeSettings { get }
    func getVariable(_ name: String) -> TI84Value?
    func setVariable(_ name: String, _ value: TI84Value) throws
    func getList(_ name: String) -> [Double]?
    func setList(_ name: String, _ value: [Double]) throws
    func getMatrix(_ name: String) -> [[Double]]?
    func setMatrix(_ name: String, _ value: [[Double]]) throws
    func getStringVar(_ name: String) -> String?
    func setStringVar(_ name: String, _ value: String) throws
    func getYVar(_ index: Int) -> String?
    func evaluateYVar(_ index: Int, x: Double) throws -> Double
}

/// Evaluates AST nodes to produce TI84Values.
/// Handles list broadcasting (element-wise operations on lists).
public class Evaluator {
    public weak var context: EvaluationContext?
    private let functionEvaluator = FunctionEvaluator()

    public init(context: EvaluationContext? = nil) {
        self.context = context
    }

    // MARK: - Main Evaluation

    public func evaluate(_ node: ASTNode) throws -> TI84Value {
        switch node {
        case .number(let v):
            return .real(v)

        case .string(let s):
            return .string(s)

        case .pi:
            return .real(Double.pi)

        case .eulerE:
            return .real(M_E)

        case .imaginaryI:
            return .complex(0, 1)

        case .ans:
            return context?.ans ?? .real(0)

        case .variable(let name):
            guard let value = context?.getVariable(name) else {
                return .real(0) // TI-84 defaults unset variables to 0
            }
            return value

        case .listVar(let name):
            guard let list = context?.getList(name) else {
                throw CalcError.undefined
            }
            return .list(list)

        case .matrixVar(let name):
            guard let matrix = context?.getMatrix(name) else {
                throw CalcError.undefined
            }
            return .matrix(matrix)

        case .stringVar(let name):
            guard let str = context?.getStringVar(name) else {
                throw CalcError.undefined
            }
            return .string(str)

        case .yVar(let index):
            guard let expr = context?.getYVar(index), !expr.isEmpty else {
                throw CalcError.undefined
            }
            return .string(expr)

        case .binary(let op, let leftNode, let rightNode):
            let left = try evaluate(leftNode)
            let right = try evaluate(rightNode)
            return try evaluateBinary(op, left, right)

        case .unaryPrefix(let op, let operand):
            let value = try evaluate(operand)
            return try evaluateUnaryPrefix(op, value)

        case .unaryPostfix(let operand, let op):
            let value = try evaluate(operand)
            return try evaluateUnaryPostfix(value, op)

        case .functionCall(let fn, let argNodes):
            let args = try argNodes.map { try evaluate($0) }
            return try functionEvaluator.evaluate(fn, args: args, context: context)

        case .listLiteral(let elements):
            let values = try elements.map { try evaluate($0) }
            let doubles = try values.map { v -> Double in
                guard let d = v.asReal else { throw CalcError.dataType }
                return d
            }
            return .list(doubles)

        case .matrixLiteral(let rows):
            let matrix = try rows.map { row -> [Double] in
                try row.map { elem -> Double in
                    let v = try evaluate(elem)
                    guard let d = v.asReal else { throw CalcError.dataType }
                    return d
                }
            }
            // Verify all rows same length
            if let firstCount = matrix.first?.count {
                guard matrix.allSatisfy({ $0.count == firstCount }) else {
                    throw CalcError.dimensionMismatch
                }
            }
            return .matrix(matrix)

        case .elementAccess(let target, let indices):
            return try evaluateElementAccess(target, indices: indices)

        case .store(let expr, let target):
            let value = try evaluate(expr)
            try storeValue(value, to: target)
            return value

        case .implicitMul(let left, let right):
            let lv = try evaluate(left)
            let rv = try evaluate(right)
            return try evaluateBinary(.multiply, lv, rv)
        }
    }

    // MARK: - Binary Operations

    private func evaluateBinary(_ op: BinaryOp, _ left: TI84Value, _ right: TI84Value) throws -> TI84Value {
        // List broadcasting: if one side is a list, apply element-wise
        if case .list(let lList) = left, case .list(let rList) = right {
            guard lList.count == rList.count else { throw CalcError.dimensionMismatch }
            let result = try zip(lList, rList).map { try binaryReal(op, $0.0, $0.1) }
            return .list(result)
        }

        if case .list(let lList) = left, let rVal = right.asReal {
            let result = try lList.map { try binaryReal(op, $0, rVal) }
            return .list(result)
        }

        if let lVal = left.asReal, case .list(let rList) = right {
            let result = try rList.map { try binaryReal(op, lVal, $0) }
            return .list(result)
        }

        // Matrix operations
        if case .matrix(let lMat) = left, case .matrix(let rMat) = right {
            return try matrixBinary(op, lMat, rMat)
        }

        if case .matrix(let lMat) = left, let rVal = right.asReal {
            return try matrixScalar(op, lMat, rVal)
        }

        if let lVal = left.asReal, case .matrix(let rMat) = right {
            return try scalarMatrix(op, lVal, rMat)
        }

        // String concatenation
        if case .string(let lStr) = left, case .string(let rStr) = right, op == .add {
            return .string(lStr + rStr)
        }

        // Real number operations
        guard let lVal = left.asReal, let rVal = right.asReal else {
            throw CalcError.dataType
        }

        return .real(try binaryReal(op, lVal, rVal))
    }

    private func binaryReal(_ op: BinaryOp, _ a: Double, _ b: Double) throws -> Double {
        switch op {
        case .add: return a + b
        case .subtract: return a - b
        case .multiply: return a * b
        case .divide:
            guard b != 0 else { throw CalcError.divideByZero }
            return a / b
        case .power:
            let result = pow(a, b)
            guard result.isFinite else { throw CalcError.overflow }
            return result
        case .nPr:
            return try permutation(Int(a), Int(b))
        case .nCr:
            return try combination(Int(a), Int(b))
        case .equal: return a == b ? 1 : 0
        case .notEqual: return a != b ? 1 : 0
        case .lessThan: return a < b ? 1 : 0
        case .greaterThan: return a > b ? 1 : 0
        case .lessEqual: return a <= b ? 1 : 0
        case .greaterEqual: return a >= b ? 1 : 0
        case .logicalAnd: return (a != 0 && b != 0) ? 1 : 0
        case .logicalOr: return (a != 0 || b != 0) ? 1 : 0
        case .logicalXor: return ((a != 0) != (b != 0)) ? 1 : 0
        }
    }

    // MARK: - Matrix Binary Operations

    private func matrixBinary(_ op: BinaryOp, _ a: [[Double]], _ b: [[Double]]) throws -> TI84Value {
        guard a.count == b.count, a[0].count == b[0].count else {
            if op == .multiply {
                // Matrix multiplication: A[m×n] * B[n×p] → C[m×p]
                guard a[0].count == b.count else { throw CalcError.dimensionMismatch }
                return .matrix(matrixMultiply(a, b))
            }
            throw CalcError.dimensionMismatch
        }

        switch op {
        case .add:
            return .matrix(zip(a, b).map { zip($0, $1).map(+) })
        case .subtract:
            return .matrix(zip(a, b).map { zip($0, $1).map(-) })
        case .multiply:
            // Element-wise if same dimensions? No — TI-84 does matrix multiply
            guard a[0].count == b.count else { throw CalcError.dimensionMismatch }
            return .matrix(matrixMultiply(a, b))
        default:
            throw CalcError.dataType
        }
    }

    private func matrixMultiply(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        let m = a.count
        let n = a[0].count
        let p = b[0].count
        var result = Array(repeating: Array(repeating: 0.0, count: p), count: m)
        for i in 0..<m {
            for j in 0..<p {
                var sum = 0.0
                for k in 0..<n {
                    sum += a[i][k] * b[k][j]
                }
                result[i][j] = sum
            }
        }
        return result
    }

    private func matrixScalar(_ op: BinaryOp, _ mat: [[Double]], _ scalar: Double) throws -> TI84Value {
        switch op {
        case .multiply:
            return .matrix(mat.map { $0.map { $0 * scalar } })
        case .divide:
            guard scalar != 0 else { throw CalcError.divideByZero }
            return .matrix(mat.map { $0.map { $0 / scalar } })
        case .power:
            // Matrix power: must be square, integer exponent
            guard mat.count == mat[0].count else { throw CalcError.dimensionMismatch }
            let n = Int(scalar)
            guard Double(n) == scalar, n >= 0 else { throw CalcError.dataType }
            return .matrix(try matrixPower(mat, n))
        default:
            throw CalcError.dataType
        }
    }

    private func scalarMatrix(_ op: BinaryOp, _ scalar: Double, _ mat: [[Double]]) throws -> TI84Value {
        switch op {
        case .multiply:
            return .matrix(mat.map { $0.map { scalar * $0 } })
        default:
            throw CalcError.dataType
        }
    }

    private func matrixPower(_ mat: [[Double]], _ n: Int) throws -> [[Double]] {
        let size = mat.count
        if n == 0 {
            // Identity matrix
            var result = Array(repeating: Array(repeating: 0.0, count: size), count: size)
            for i in 0..<size { result[i][i] = 1.0 }
            return result
        }
        var result = mat
        for _ in 1..<n {
            result = matrixMultiply(result, mat)
        }
        return result
    }

    // MARK: - Unary Operations

    private func evaluateUnaryPrefix(_ op: UnaryOp, _ value: TI84Value) throws -> TI84Value {
        switch op {
        case .negate:
            switch value {
            case .real(let v): return .real(-v)
            case .complex(let r, let i): return .complex(-r, -i)
            case .list(let l): return .list(l.map { -$0 })
            case .matrix(let m): return .matrix(m.map { $0.map { -$0 } })
            default: throw CalcError.dataType
            }
        case .logicalNot:
            guard let v = value.asReal else { throw CalcError.dataType }
            return .real(v == 0 ? 1 : 0)
        }
    }

    private func evaluateUnaryPostfix(_ value: TI84Value, _ op: PostfixOp) throws -> TI84Value {
        guard let v = value.asReal else {
            // List broadcasting for postfix
            if case .list(let list) = value {
                let results = try list.map { try applyPostfix($0, op) }
                return .list(results)
            }
            throw CalcError.dataType
        }
        return .real(try applyPostfix(v, op))
    }

    private func applyPostfix(_ v: Double, _ op: PostfixOp) throws -> Double {
        switch op {
        case .factorial:
            return try factorial(v)
        case .squared:
            return v * v
        case .cubed:
            return v * v * v
        case .inverse:
            guard v != 0 else { throw CalcError.divideByZero }
            return 1.0 / v
        case .degrees:
            // Convert degrees to radians
            return v * .pi / 180.0
        case .radians:
            return v
        case .transpose:
            throw CalcError.dataType // Handled at matrix level
        case .percent:
            return v / 100.0
        }
    }

    // MARK: - Element Access

    private func evaluateElementAccess(_ target: ASTNode, indices: [ASTNode]) throws -> TI84Value {
        let targetValue = try evaluate(target)
        let indexValues = try indices.map { try evaluate($0) }

        switch targetValue {
        case .list(let list):
            guard indices.count == 1 else { throw CalcError.argument }
            guard let idx = indexValues[0].asInt, idx >= 1, idx <= list.count else {
                throw CalcError.invalidDim
            }
            return .real(list[idx - 1]) // 1-indexed

        case .matrix(let matrix):
            guard indices.count == 2 else { throw CalcError.argument }
            guard let row = indexValues[0].asInt, let col = indexValues[1].asInt,
                  row >= 1, row <= matrix.count,
                  col >= 1, col <= matrix[0].count else {
                throw CalcError.invalidDim
            }
            return .real(matrix[row - 1][col - 1]) // 1-indexed

        default:
            // Y-var evaluation: Y1(value) evaluates the function at that X
            if case .yVar(let index) = target {
                guard let x = indexValues[0].asReal else { throw CalcError.dataType }
                guard let result = try context?.evaluateYVar(index, x: x) else {
                    throw CalcError.undefined
                }
                return .real(result)
            }
            throw CalcError.dataType
        }
    }

    // MARK: - Store

    private func storeValue(_ value: TI84Value, to target: ASTNode) throws {
        switch target {
        case .variable(let name):
            try context?.setVariable(name, value)

        case .listVar(let name):
            guard let list = value.asList else { throw CalcError.dataType }
            try context?.setList(name, list)

        case .matrixVar(let name):
            guard let matrix = value.asMatrix else { throw CalcError.dataType }
            try context?.setMatrix(name, matrix)

        case .stringVar(let name):
            guard let str = value.asString else { throw CalcError.dataType }
            try context?.setStringVar(name, str)

        case .elementAccess(let target, let indices):
            // Store to element: 5→L1(3)
            try storeToElement(value, target: target, indices: indices)

        default:
            throw CalcError.syntax
        }
    }

    private func storeToElement(_ value: TI84Value, target: ASTNode, indices: [ASTNode]) throws {
        let indexValues = try indices.map { try evaluate($0) }

        switch target {
        case .listVar(let name):
            guard let val = value.asReal else { throw CalcError.dataType }
            guard var list = context?.getList(name) else { throw CalcError.undefined }
            guard indices.count == 1, let idx = indexValues[0].asInt, idx >= 1 else {
                throw CalcError.invalidDim
            }
            // TI-84 allows storing to dim+1 to extend
            while list.count < idx {
                list.append(0)
            }
            list[idx - 1] = val
            try context?.setList(name, list)

        case .matrixVar(let name):
            guard let val = value.asReal else { throw CalcError.dataType }
            guard var matrix = context?.getMatrix(name) else { throw CalcError.undefined }
            guard indices.count == 2,
                  let row = indexValues[0].asInt, let col = indexValues[1].asInt,
                  row >= 1, row <= matrix.count,
                  col >= 1, col <= matrix[0].count else {
                throw CalcError.invalidDim
            }
            matrix[row - 1][col - 1] = val
            try context?.setMatrix(name, matrix)

        default:
            throw CalcError.syntax
        }
    }

    // MARK: - Math Helpers

    private func factorial(_ n: Double) throws -> Double {
        guard n >= 0, n == floor(n), n <= 69 else {
            if n < 0 || n != floor(n) { throw CalcError.domain }
            throw CalcError.overflow
        }
        let intN = Int(n)
        if intN == 0 { return 1 }
        var result = 1.0
        for i in 1...intN {
            result *= Double(i)
            guard result.isFinite else { throw CalcError.overflow }
        }
        return result
    }

    private func permutation(_ n: Int, _ r: Int) throws -> Double {
        guard n >= 0, r >= 0, r <= n else { throw CalcError.domain }
        var result = 1.0
        for i in (n - r + 1)...n {
            result *= Double(i)
        }
        return result
    }

    private func combination(_ n: Int, _ r: Int) throws -> Double {
        guard n >= 0, r >= 0, r <= n else { throw CalcError.domain }
        let perm = try permutation(n, r)
        let rFact = try factorial(Double(r))
        return perm / rFact
    }
}
