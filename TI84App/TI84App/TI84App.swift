import SwiftUI

@main
struct TI84App: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            CalculatorShell()
                .environmentObject(appState)
                .frame(minWidth: 420, minHeight: 760)
                .frame(idealWidth: 420, idealHeight: 760)
                .background(Color.black)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 760)
    }
}
