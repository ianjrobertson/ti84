import Foundation
import TI84Core

/// ViewModel for menu overlay interaction.
class MenuViewModel: ObservableObject {
    weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    func handleKey(_ key: CalcKey) {
        guard let state = appState, var menu = state.activeMenu else { return }

        let tab = menu.definition.tabs[menu.selectedTab]

        switch key {
        case .up:
            if menu.selectedItem > 0 {
                menu.selectedItem -= 1
                state.activeMenu = menu
            }

        case .down:
            if menu.selectedItem < tab.items.count - 1 {
                menu.selectedItem += 1
                state.activeMenu = menu
            }

        case .left:
            if menu.selectedTab > 0 {
                menu.selectedTab -= 1
                menu.selectedItem = 0
                state.activeMenu = menu
            }

        case .right:
            if menu.selectedTab < menu.definition.tabs.count - 1 {
                menu.selectedTab += 1
                menu.selectedItem = 0
                state.activeMenu = menu
            }

        case .enter:
            selectCurrentItem()

        case .clear:
            state.activeMenu = nil

        // Number keys 1-9 for quick selection
        case .num1: selectItem(at: 0)
        case .num2: selectItem(at: 1)
        case .num3: selectItem(at: 2)
        case .num4: selectItem(at: 3)
        case .num5: selectItem(at: 4)
        case .num6: selectItem(at: 5)
        case .num7: selectItem(at: 6)
        case .num8: selectItem(at: 7)
        case .num9: selectItem(at: 8)

        default:
            break
        }
    }

    private func selectCurrentItem() {
        guard let state = appState, let menu = state.activeMenu else { return }
        let tab = menu.definition.tabs[menu.selectedTab]
        guard menu.selectedItem < tab.items.count else { return }
        let item = tab.items[menu.selectedItem]
        applyMenuSelection(item)
    }

    private func selectItem(at index: Int) {
        guard let state = appState, let menu = state.activeMenu else { return }
        let tab = menu.definition.tabs[menu.selectedTab]
        guard index < tab.items.count else { return }
        let item = tab.items[index]
        applyMenuSelection(item)
    }

    private func applyMenuSelection(_ item: MenuItem) {
        guard let state = appState else { return }

        // Handle special menu items
        switch item.id {
        case "edit":
            state.activeMenu = nil
            state.navigateTo(.listEditor)
            return
        case "zstandard":
            state.activeMenu = nil
            state.calculatorState.windowParameters = .standard
            state.navigateTo(.graph)
            return
        case "ztrig":
            state.activeMenu = nil
            state.calculatorState.windowParameters = .trig
            state.navigateTo(.graph)
            return
        case "zdecimal":
            state.activeMenu = nil
            state.calculatorState.windowParameters = .decimal
            state.navigateTo(.graph)
            return
        case "zinteger":
            state.activeMenu = nil
            state.calculatorState.windowParameters = .integer
            state.navigateTo(.graph)
            return
        case "zsquare":
            state.activeMenu = nil
            state.calculatorState.windowParameters = state.calculatorState.windowParameters.squared(
                viewWidth: 380, viewHeight: 260
            )
            state.navigateTo(.graph)
            return
        default:
            break
        }

        // Default: insert text
        if !item.insertText.isEmpty {
            state.insertText(item.insertText)
        }
        state.activeMenu = nil
    }
}
