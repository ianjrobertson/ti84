import SwiftUI
import TI84Core
import TI84Engine

/// Root observable state coordinator.
/// Owns CalculatorState, manages active screen, dispatches key presses.
class AppState: ObservableObject {
    @Published var activeScreen: Screen = .home
    @Published var secondActive: Bool = false
    @Published var alphaActive: Bool = false
    @Published var alphaLock: Bool = false
    @Published var currentExpression: String = ""
    @Published var cursorPosition: Int = 0
    @Published var errorMessage: String? = nil
    @Published var activeMenu: ActiveMenu? = nil

    let calculatorState = CalculatorState()
    private let keyDispatcher = KeyDispatcher()

    // ViewModels
    lazy var homeVM = HomeViewModel(appState: self)
    lazy var graphVM = GraphViewModel(appState: self)
    lazy var tableVM = TableViewModel(appState: self)
    lazy var menuVM = MenuViewModel(appState: self)

    init() {
        keyDispatcher.appState = self
        StatePersistence.load(into: calculatorState)
    }

    // MARK: - Key Handling

    func handleKey(_ key: CalcKey) {
        // Clear error on any key press
        if errorMessage != nil && key != .enter {
            errorMessage = nil
            if activeScreen == .error("") {
                activeScreen = .home
            }
        }

        // Handle 2nd key
        if key == .second {
            secondActive.toggle()
            return
        }

        // Handle ALPHA key
        if key == .alpha {
            if secondActive {
                alphaLock.toggle()
                alphaActive = alphaLock
                secondActive = false
            } else {
                alphaActive.toggle()
                if !alphaActive { alphaLock = false }
            }
            return
        }

        // Resolve 2nd function keys
        let resolvedKey: CalcKey
        if secondActive {
            resolvedKey = resolve2nd(key)
            secondActive = false
        } else {
            resolvedKey = key
        }

        // Handle ALPHA input
        if alphaActive && !alphaLock {
            if let ch = resolvedKey.alphaCharacter {
                insertText(ch)
                alphaActive = false
                return
            }
            alphaActive = false
        } else if alphaLock {
            if let ch = resolvedKey.alphaCharacter {
                insertText(ch)
                return
            }
        }

        // Handle menu selection
        if activeMenu != nil {
            menuVM.handleKey(resolvedKey)
            return
        }

        // Dispatch to appropriate handler
        keyDispatcher.dispatch(resolvedKey)
    }

    // MARK: - 2nd Key Resolution

    private func resolve2nd(_ key: CalcKey) -> CalcKey {
        switch key {
        case .y_equals: return .statPlot
        case .window: return .tableSet
        case .zoom: return .format
        case .trace: return .calc
        case .graph: return .table
        case .mode: return .quit
        case .del: return .ins
        case .stat: return .list
        case .math: return .test
        case .apps: return .angle
        case .prgm: return .draw
        case .vars: return .distr
        case .inverse: return .matrix
        case .squared: return .sqrt
        case .comma: return .ee
        case .leftParen: return .lBracket // Actually { on TI-84
        case .rightParen: return .rBracket // Actually } on TI-84
        case .power: return .pi
        case .log: return .tenPower
        case .ln: return .ePower
        case .store: return .recall
        case .num0: return .catalog
        case .decimal: return .i_imaginary
        case .negate: return .ans
        case .enter: return .entry
        case .add: return .ans     // Mem isn't a real key
        default: return key
        }
    }

    // MARK: - Text Input

    func insertText(_ text: String) {
        let index = currentExpression.index(currentExpression.startIndex,
                                            offsetBy: min(cursorPosition, currentExpression.count))
        currentExpression.insert(contentsOf: text, at: index)
        cursorPosition += text.count
    }

    func deleteChar() {
        guard cursorPosition > 0 else { return }
        let index = currentExpression.index(currentExpression.startIndex, offsetBy: cursorPosition - 1)
        currentExpression.remove(at: index)
        cursorPosition -= 1
    }

    func moveCursorLeft() {
        if cursorPosition > 0 { cursorPosition -= 1 }
    }

    func moveCursorRight() {
        if cursorPosition < currentExpression.count { cursorPosition += 1 }
    }

    // MARK: - Evaluate

    func evaluateCurrentExpression() {
        let expr = currentExpression.trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty else { return }

        do {
            let parser = try Parser(expression: expr)
            let ast = try parser.parse()
            let evaluator = Evaluator(context: calculatorState)
            let result = try evaluator.evaluate(ast)

            calculatorState.ans = result
            let formatter = TI84NumberFormatter(settings: calculatorState.modeSettings)
            let resultStr = formatter.format(result)

            calculatorState.history.append((expression: expr, result: resultStr))
            currentExpression = ""
            cursorPosition = 0
        } catch let error as CalcError {
            errorMessage = error.message
        } catch {
            errorMessage = "ERR:SYNTAX"
        }
    }

    // MARK: - Navigation

    func navigateTo(_ screen: Screen) {
        activeScreen = screen
    }

    func goHome() {
        activeScreen = .home
    }

    // MARK: - State Persistence

    func saveState() {
        StatePersistence.save(calculatorState)
    }
}

/// Represents an active menu overlay.
struct ActiveMenu: Equatable {
    let definition: MenuDefinition
    var selectedTab: Int = 0
    var selectedItem: Int = 0

    static func == (lhs: ActiveMenu, rhs: ActiveMenu) -> Bool {
        lhs.definition.title == rhs.definition.title &&
        lhs.selectedTab == rhs.selectedTab &&
        lhs.selectedItem == rhs.selectedItem
    }
}
