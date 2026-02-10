import Foundation
import TI84Core
import TI84Engine

/// Routes key presses to the active screen's handler.
class KeyDispatcher {
    weak var appState: AppState?

    func dispatch(_ key: CalcKey) {
        guard let state = appState else { return }

        // Global keys
        switch key {
        case .quit:
            state.goHome()
            return
        case .clear:
            if state.activeScreen == .home {
                if state.currentExpression.isEmpty {
                    state.calculatorState.clearHome()
                } else {
                    state.currentExpression = ""
                    state.cursorPosition = 0
                }
            } else {
                state.goHome()
            }
            return
        case .y_equals:
            state.navigateTo(.yEquals)
            return
        case .window:
            state.navigateTo(.window)
            return
        case .zoom:
            state.activeMenu = ActiveMenu(definition: zoomMenu)
            return
        case .trace:
            state.navigateTo(.graph)
            state.graphVM.startTrace()
            return
        case .graph:
            state.navigateTo(.graph)
            return
        case .table:
            state.navigateTo(.table)
            return
        case .tableSet:
            state.navigateTo(.tableSetup)
            return
        case .mode:
            state.navigateTo(.mode)
            return
        case .stat:
            state.activeMenu = ActiveMenu(definition: StandardMenus.stat)
            return
        case .math:
            state.activeMenu = ActiveMenu(definition: StandardMenus.math)
            return
        case .prgm:
            state.activeMenu = ActiveMenu(definition: programMenu)
            return
        case .matrix:
            state.navigateTo(.matrixEditor)
            return
        case .list:
            state.navigateTo(.listEditor)
            return
        default:
            break
        }

        // Screen-specific handling
        switch state.activeScreen {
        case .home:
            handleHomeKey(key)
        case .graph:
            handleGraphKey(key)
        case .yEquals:
            handleYEqualsKey(key)
        case .window:
            handleWindowKey(key)
        case .table:
            handleTableKey(key)
        default:
            handleHomeKey(key) // Default: treat as home screen input
        }
    }

    // MARK: - Home Screen Keys

    private func handleHomeKey(_ key: CalcKey) {
        guard let state = appState else { return }

        switch key {
        case .enter:
            state.evaluateCurrentExpression()

        case .del:
            state.deleteChar()

        case .left:
            state.moveCursorLeft()

        case .right:
            state.moveCursorRight()

        case .up:
            // Navigate history
            break

        case .down:
            break

        // Digits
        case .num0: state.insertText("0")
        case .num1: state.insertText("1")
        case .num2: state.insertText("2")
        case .num3: state.insertText("3")
        case .num4: state.insertText("4")
        case .num5: state.insertText("5")
        case .num6: state.insertText("6")
        case .num7: state.insertText("7")
        case .num8: state.insertText("8")
        case .num9: state.insertText("9")
        case .decimal: state.insertText(".")

        // Operators
        case .add: state.insertText("+")
        case .subtract: state.insertText("-")
        case .multiply: state.insertText("*")
        case .divide: state.insertText("/")
        case .power: state.insertText("^")

        // Grouping
        case .leftParen: state.insertText("(")
        case .rightParen: state.insertText(")")
        case .comma: state.insertText(",")

        // Functions
        case .sin: state.insertText("sin(")
        case .cos: state.insertText("cos(")
        case .tan: state.insertText("tan(")
        case .log: state.insertText("log(")
        case .ln: state.insertText("ln(")
        case .squared: state.insertText("^2")
        case .inverse: state.insertText("^(-1)")

        // 2nd functions
        case .sqrt: state.insertText("√(")
        case .pi: state.insertText("π")
        case .tenPower: state.insertText("10^(")
        case .ePower: state.insertText("e^(")
        case .ans: state.insertText("Ans")
        case .i_imaginary: state.insertText("i")
        case .ee: state.insertText("E")
        case .lBracket: state.insertText("{")
        case .rBracket: state.insertText("}")
        case .lBrace: state.insertText("{")
        case .rBrace: state.insertText("}")

        // Store
        case .store: state.insertText("→")

        // Negation
        case .negate: state.insertText("-")

        // Variable
        case .xTThetaN: state.insertText("X")

        default:
            break
        }
    }

    // MARK: - Graph Screen Keys

    private func handleGraphKey(_ key: CalcKey) {
        guard let state = appState else { return }

        switch key {
        case .left: state.graphVM.traceLeft()
        case .right: state.graphVM.traceRight()
        case .up: state.graphVM.traceFunctionUp()
        case .down: state.graphVM.traceFunctionDown()
        case .enter: break
        default: break
        }
    }

    // MARK: - Y= Editor Keys

    private func handleYEqualsKey(_ key: CalcKey) {
        // Delegate to home key handling for text input
        handleHomeKey(key)
    }

    // MARK: - Window Editor Keys

    private func handleWindowKey(_ key: CalcKey) {
        handleHomeKey(key)
    }

    // MARK: - Table Keys

    private func handleTableKey(_ key: CalcKey) {
        guard let state = appState else { return }
        switch key {
        case .up: state.tableVM.moveUp()
        case .down: state.tableVM.moveDown()
        default: break
        }
    }

    // MARK: - Menu Definitions

    private var zoomMenu: MenuDefinition {
        MenuDefinition(title: "ZOOM", tabs: [
            MenuTab(name: "ZOOM", items: [
                MenuItem(id: "zbox", label: "ZBox", insertText: ""),
                MenuItem(id: "zin", label: "Zoom In", insertText: ""),
                MenuItem(id: "zout", label: "Zoom Out", insertText: ""),
                MenuItem(id: "zdecimal", label: "ZDecimal", insertText: ""),
                MenuItem(id: "zsquare", label: "ZSquare", insertText: ""),
                MenuItem(id: "zstandard", label: "ZStandard", insertText: ""),
                MenuItem(id: "ztrig", label: "ZTrig", insertText: ""),
                MenuItem(id: "zinteger", label: "ZInteger", insertText: ""),
                MenuItem(id: "zstat", label: "ZoomStat", insertText: ""),
                MenuItem(id: "zfit", label: "ZoomFit", insertText: ""),
            ]),
            MenuTab(name: "MEMORY", items: [
                MenuItem(id: "zprev", label: "ZPrevious", insertText: ""),
                MenuItem(id: "zsto", label: "ZoomSto", insertText: ""),
                MenuItem(id: "zrcl", label: "ZoomRcl", insertText: ""),
            ]),
        ])
    }

    private var programMenu: MenuDefinition {
        MenuDefinition(title: "PRGM", tabs: [
            MenuTab(name: "EXEC", items: []),
            MenuTab(name: "EDIT", items: []),
            MenuTab(name: "NEW", items: [
                MenuItem(id: "new", label: "Create New", insertText: ""),
            ]),
        ])
    }
}
