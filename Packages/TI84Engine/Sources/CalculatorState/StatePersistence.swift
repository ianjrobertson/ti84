import Foundation
import TI84Core

/// Handles saving and loading calculator state to/from disk.
public struct StatePersistence {
    private static var saveURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TI84Calculator", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("state.json")
    }

    public static func save(_ state: CalculatorState) {
        let data = SavedState(from: state)
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: saveURL)
        }
    }

    public static func load(into state: CalculatorState) {
        guard let data = try? Data(contentsOf: saveURL),
              let saved = try? JSONDecoder().decode(SavedState.self, from: data) else {
            return
        }
        saved.apply(to: state)
    }
}

private struct SavedState: Codable {
    var variables: [String: Double] = [:]
    var lists: [String: [Double]] = [:]
    var matrices: [String: [[Double]]] = [:]
    var stringVars: [String: String] = [:]
    var yVars: [String] = []
    var yVarEnabled: [Bool] = []
    var programs: [String: String] = [:]
    var angleUnit: String = "radian"
    var numberFormat: String = "normal"
    var graphMode: String = "function"

    init(from state: CalculatorState) {
        for (key, val) in state.variables {
            if let r = val.asReal { variables[key] = r }
        }
        lists = state.lists
        matrices = state.matrices
        stringVars = state.stringVars
        yVars = state.yVars
        yVarEnabled = state.yVarEnabled
        programs = state.programs
        angleUnit = state.modeSettings.angleUnit.rawValue
        numberFormat = state.modeSettings.numberFormat.rawValue
        graphMode = state.modeSettings.graphMode.rawValue
    }

    func apply(to state: CalculatorState) {
        for (key, val) in variables {
            state.variables[key] = .real(val)
        }
        state.lists = lists
        state.matrices = matrices
        state.stringVars = stringVars
        if yVars.count == 10 { state.yVars = yVars }
        if yVarEnabled.count == 10 { state.yVarEnabled = yVarEnabled }
        state.programs = programs
        if let unit = ModeSettings.AngleUnit(rawValue: angleUnit) {
            state.modeSettings.angleUnit = unit
        }
        if let fmt = ModeSettings.NumberFormat(rawValue: numberFormat) {
            state.modeSettings.numberFormat = fmt
        }
        if let gm = ModeSettings.GraphMode(rawValue: graphMode) {
            state.modeSettings.graphMode = gm
        }
    }
}
