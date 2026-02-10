import Foundation
import TI84Core
import TI84Engine

/// ViewModel for the home screen.
class HomeViewModel: ObservableObject {
    weak var appState: AppState?
    @Published var historyScrollPosition: Int = 0

    init(appState: AppState) {
        self.appState = appState
    }

    func scrollToBottom() {
        guard let state = appState else { return }
        historyScrollPosition = state.calculatorState.history.count - 1
    }
}
