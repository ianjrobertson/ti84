import Foundation

/// Calculator mode settings matching the TI-84 MODE screen.
public struct ModeSettings: Equatable, Sendable {
    /// Number display format
    public enum NumberFormat: String, CaseIterable, Sendable {
        case normal = "Normal"
        case sci = "Sci"
        case eng = "Eng"
    }

    /// Fixed decimal places (0-9), or nil for Float
    public enum FloatSetting: Equatable, Sendable {
        case float
        case fixed(Int) // 0-9
    }

    /// Angle unit
    public enum AngleUnit: String, CaseIterable, Sendable {
        case radian = "Radian"
        case degree = "Degree"
    }

    /// Graph type
    public enum GraphMode: String, CaseIterable, Sendable {
        case function = "Func"
        case parametric = "Par"
        case polar = "Pol"
        case sequence = "Seq"
    }

    /// Complex number format
    public enum ComplexFormat: String, CaseIterable, Sendable {
        case real = "Real"
        case rectangularABI = "a+bi"
        case polarRE = "re^θi"
    }

    /// Sequential or simultaneous graphing
    public enum GraphOrder: String, CaseIterable, Sendable {
        case sequential = "Sequential"
        case simultaneous = "Simul"
    }

    public var numberFormat: NumberFormat
    public var floatSetting: FloatSetting
    public var angleUnit: AngleUnit
    public var graphMode: GraphMode
    public var complexFormat: ComplexFormat
    public var graphOrder: GraphOrder
    public var isConnected: Bool  // Connected vs Dot mode
    public var isFullScreen: Bool // Full vs Horizontal vs Graph-Table

    public init() {
        self.numberFormat = .normal
        self.floatSetting = .float
        self.angleUnit = .radian
        self.graphMode = .function
        self.complexFormat = .real
        self.graphOrder = .sequential
        self.isConnected = true
        self.isFullScreen = true
    }
}
