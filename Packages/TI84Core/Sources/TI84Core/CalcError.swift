import Foundation

/// TI-84 calculator errors that match the real calculator's error messages.
public enum CalcError: Error, Equatable, Sendable {
    case syntax
    case divideByZero
    case overflow
    case domain
    case dataType
    case argument
    case dimensionMismatch
    case singular
    case undefined
    case memory
    case invalid
    case stat
    case statPlot
    case invalidDim
    case archived
    case iterations
    case labelNotFound(String)
    case breakProgram
    case nonReal

    public var message: String {
        switch self {
        case .syntax: return "ERR:SYNTAX"
        case .divideByZero: return "ERR:DIVIDE BY 0"
        case .overflow: return "ERR:OVERFLOW"
        case .domain: return "ERR:DOMAIN"
        case .dataType: return "ERR:DATA TYPE"
        case .argument: return "ERR:ARGUMENT"
        case .dimensionMismatch: return "ERR:DIM MISMATCH"
        case .singular: return "ERR:SINGULAR MAT"
        case .undefined: return "ERR:UNDEFINED"
        case .memory: return "ERR:MEMORY"
        case .invalid: return "ERR:INVALID"
        case .stat: return "ERR:STAT"
        case .statPlot: return "ERR:STAT PLOT"
        case .invalidDim: return "ERR:INVALID DIM"
        case .archived: return "ERR:ARCHIVED"
        case .iterations: return "ERR:NO SIGN CHNG"
        case .labelNotFound(let lbl): return "ERR:LABEL \(lbl)"
        case .breakProgram: return "ERR:BREAK"
        case .nonReal: return "ERR:NONREAL ANS"
        }
    }
}
