import Foundation
import TI84Core

/// Central calculator state — owns all variables, lists, matrices, Y-vars, settings.
/// Conforms to EvaluationContext for use with the Evaluator.
public class CalculatorState: EvaluationContext, ObservableObject {
    // Variables A-Z, θ
    @Published public var variables: [String: TI84Value] = [:]

    // Lists L1-L6 plus custom lists
    @Published public var lists: [String: [Double]] = [
        "L1": [], "L2": [], "L3": [], "L4": [], "L5": [], "L6": []
    ]

    // Matrices [A]-[J]
    @Published public var matrices: [String: [[Double]]] = [:]

    // String variables Str0-Str9
    @Published public var stringVars: [String: String] = [:]

    // Y-variables (function equations)
    @Published public var yVars: [String] = Array(repeating: "", count: 10) // Y1-Y0 (index 0=Y1..9=Y0)
    @Published public var yVarEnabled: [Bool] = Array(repeating: true, count: 10)

    // Parametric equations
    @Published public var xTVars: [String] = Array(repeating: "", count: 6) // X1T-X6T
    @Published public var yTVars: [String] = Array(repeating: "", count: 6) // Y1T-Y6T

    // Polar equations
    @Published public var rVars: [String] = Array(repeating: "", count: 6) // r1-r6

    // Sequence equations
    @Published public var uVars: [String] = Array(repeating: "", count: 3) // u, v, w

    // Ans — last computed result
    @Published public var ans: TI84Value = .real(0)

    // Mode settings
    @Published public var modeSettings = ModeSettings()

    // Window parameters
    @Published public var windowParameters = WindowParameters()

    // Table settings
    @Published public var tableStart: Double = 0
    @Published public var tableDelta: Double = 1
    @Published public var tableIndependent: TableMode = .auto
    @Published public var tableDependent: TableMode = .auto

    // Graph format settings
    @Published public var showAxes: Bool = true
    @Published public var showGrid: Bool = false
    @Published public var showLabels: Bool = false

    // Expression/result history for home screen
    @Published public var history: [(expression: String, result: String)] = []

    // Programs
    @Published public var programs: [String: String] = [:] // name → source code

    // Random seed
    public var randomSeed: UInt64 = 0

    public enum TableMode: String, Sendable {
        case auto = "Auto"
        case ask = "Ask"
    }

    public init() {}

    // MARK: - EvaluationContext

    public func getVariable(_ name: String) -> TI84Value? {
        return variables[name]
    }

    public func setVariable(_ name: String, _ value: TI84Value) throws {
        variables[name] = value
    }

    public func getList(_ name: String) -> [Double]? {
        return lists[name]
    }

    public func setList(_ name: String, _ value: [Double]) throws {
        lists[name] = value
    }

    public func getMatrix(_ name: String) -> [[Double]]? {
        return matrices[name]
    }

    public func setMatrix(_ name: String, _ value: [[Double]]) throws {
        matrices[name] = value
    }

    public func getStringVar(_ name: String) -> String? {
        return stringVars[name]
    }

    public func setStringVar(_ name: String, _ value: String) throws {
        stringVars[name] = value
    }

    public func getYVar(_ index: Int) -> String? {
        let adjustedIndex = index == 0 ? 9 : index - 1
        guard adjustedIndex >= 0 && adjustedIndex < 10 else { return nil }
        let expr = yVars[adjustedIndex]
        return expr.isEmpty ? nil : expr
    }

    public func evaluateYVar(_ index: Int, x: Double) throws -> Double {
        guard let expr = getYVar(index), !expr.isEmpty else {
            throw CalcError.undefined
        }

        // Temporarily set X to the given value
        let oldX = variables["X"]
        variables["X"] = .real(x)
        defer { variables["X"] = oldX }

        // Parse and evaluate
        let parser = try Parser(expression: expr)
        let ast = try parser.parse()
        let evaluator = Evaluator(context: self)
        let result = try evaluator.evaluate(ast)

        guard let realResult = result.asReal else {
            throw CalcError.dataType
        }
        return realResult
    }

    // MARK: - Y-var helpers

    /// Get the adjusted array index for a Y-var number (1-9, 0=10)
    public func yVarIndex(_ number: Int) -> Int {
        return number == 0 ? 9 : number - 1
    }

    /// Get Y-var expression by number (1-9, 0=10)
    public func yVarExpression(_ number: Int) -> String {
        return yVars[yVarIndex(number)]
    }

    /// Set Y-var expression by number
    public func setYVarExpression(_ number: Int, _ expr: String) {
        yVars[yVarIndex(number)] = expr
    }

    /// Check if a Y-var is enabled
    public func isYVarEnabled(_ number: Int) -> Bool {
        return yVarEnabled[yVarIndex(number)]
    }

    /// Toggle Y-var enabled state
    public func toggleYVar(_ number: Int) {
        let idx = yVarIndex(number)
        yVarEnabled[idx].toggle()
    }

    // MARK: - Reset

    public func resetAll() {
        variables = [:]
        lists = ["L1": [], "L2": [], "L3": [], "L4": [], "L5": [], "L6": []]
        matrices = [:]
        stringVars = [:]
        yVars = Array(repeating: "", count: 10)
        yVarEnabled = Array(repeating: true, count: 10)
        ans = .real(0)
        modeSettings = ModeSettings()
        windowParameters = WindowParameters()
        history = []
        programs = [:]
    }

    public func clearHome() {
        history = []
    }
}
