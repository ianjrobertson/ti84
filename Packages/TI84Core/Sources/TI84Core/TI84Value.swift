import Foundation

/// Universal value type for the TI-84 calculator.
/// All operations produce and consume TI84Values.
public struct ComplexNumber: Equatable, Sendable, Hashable {
    public var re: Double
    public var im: Double

    public init(_ re: Double, _ im: Double) {
        self.re = re
        self.im = im
    }
}

public enum TI84Value: Equatable, Sendable {
    case real(Double)
    case complex(Double, Double) // (real, imaginary)
    case list([Double])
    case complexList([ComplexNumber])
    case matrix([[Double]])
    case string(String)

    // MARK: - Convenience constructors

    public static let zero = TI84Value.real(0)
    public static let one = TI84Value.real(1)
    public static let pi = TI84Value.real(Double.pi)
    public static let e = TI84Value.real(M_E)

    // MARK: - Extraction helpers

    public var asReal: Double? {
        switch self {
        case .real(let v): return v
        case .complex(let r, let i) where abs(i) < 1e-12: return r
        default: return nil
        }
    }

    public var asComplex: (Double, Double)? {
        switch self {
        case .real(let v): return (v, 0)
        case .complex(let r, let i): return (r, i)
        default: return nil
        }
    }

    public var asList: [Double]? {
        switch self {
        case .list(let l): return l
        case .real(let v): return [v]
        default: return nil
        }
    }

    public var asMatrix: [[Double]]? {
        if case .matrix(let m) = self { return m }
        return nil
    }

    public var asString: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    public var asInt: Int? {
        guard let r = asReal, r == floor(r), abs(r) < 1e15 else { return nil }
        return Int(r)
    }

    // MARK: - Type description

    public var typeName: String {
        switch self {
        case .real: return "Real"
        case .complex: return "Complex"
        case .list: return "List"
        case .complexList: return "Complex List"
        case .matrix: return "Matrix"
        case .string: return "String"
        }
    }
}
