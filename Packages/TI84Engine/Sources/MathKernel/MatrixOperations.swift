import Foundation
import TI84Core

/// Matrix mathematical operations beyond basic arithmetic.
public struct MatrixOperations {
    /// Matrix inverse using Gauss-Jordan elimination.
    public static func inverse(_ matrix: [[Double]]) throws -> [[Double]] {
        let n = matrix.count
        guard n > 0, matrix.allSatisfy({ $0.count == n }) else {
            throw CalcError.dimensionMismatch
        }

        // Augment with identity
        var augmented = matrix.enumerated().map { (i, row) -> [Double] in
            var newRow = row
            for j in 0..<n {
                newRow.append(i == j ? 1.0 : 0.0)
            }
            return newRow
        }

        // Forward elimination with partial pivoting
        for col in 0..<n {
            // Find pivot
            var maxRow = col
            for row in (col + 1)..<n {
                if abs(augmented[row][col]) > abs(augmented[maxRow][col]) {
                    maxRow = row
                }
            }

            if abs(augmented[maxRow][col]) < 1e-14 {
                throw CalcError.singular
            }

            augmented.swapAt(col, maxRow)

            // Scale pivot row
            let pivot = augmented[col][col]
            for j in 0..<(2 * n) {
                augmented[col][j] /= pivot
            }

            // Eliminate column
            for row in 0..<n {
                if row == col { continue }
                let factor = augmented[row][col]
                for j in 0..<(2 * n) {
                    augmented[row][j] -= factor * augmented[col][j]
                }
            }
        }

        // Extract inverse from augmented matrix
        return augmented.map { Array($0[n..<(2*n)]) }
    }

    /// Matrix transpose.
    public static func transpose(_ matrix: [[Double]]) -> [[Double]] {
        guard !matrix.isEmpty else { return [] }
        let rows = matrix.count
        let cols = matrix[0].count
        var result = Array(repeating: Array(repeating: 0.0, count: rows), count: cols)
        for i in 0..<rows {
            for j in 0..<cols {
                result[j][i] = matrix[i][j]
            }
        }
        return result
    }

    /// Row swap operation.
    public static func rowSwap(_ matrix: [[Double]], row1: Int, row2: Int) throws -> [[Double]] {
        guard row1 >= 1, row1 <= matrix.count, row2 >= 1, row2 <= matrix.count else {
            throw CalcError.invalidDim
        }
        var result = matrix
        result.swapAt(row1 - 1, row2 - 1)
        return result
    }

    /// Scalar row multiplication: *row(scalar, matrix, row)
    public static func scalarRow(_ matrix: [[Double]], scalar: Double, row: Int) throws -> [[Double]] {
        guard row >= 1, row <= matrix.count else { throw CalcError.invalidDim }
        var result = matrix
        result[row - 1] = result[row - 1].map { $0 * scalar }
        return result
    }

    /// Row addition: row+(matrix, srcRow, dstRow) — adds srcRow to dstRow
    public static func rowAdd(_ matrix: [[Double]], srcRow: Int, dstRow: Int) throws -> [[Double]] {
        guard srcRow >= 1, srcRow <= matrix.count, dstRow >= 1, dstRow <= matrix.count else {
            throw CalcError.invalidDim
        }
        var result = matrix
        for j in 0..<result[0].count {
            result[dstRow - 1][j] += result[srcRow - 1][j]
        }
        return result
    }

    /// Scalar row addition: *row+(scalar, matrix, srcRow, dstRow)
    public static func scalarRowAdd(_ matrix: [[Double]], scalar: Double, srcRow: Int, dstRow: Int) throws -> [[Double]] {
        guard srcRow >= 1, srcRow <= matrix.count, dstRow >= 1, dstRow <= matrix.count else {
            throw CalcError.invalidDim
        }
        var result = matrix
        for j in 0..<result[0].count {
            result[dstRow - 1][j] += scalar * result[srcRow - 1][j]
        }
        return result
    }
}
