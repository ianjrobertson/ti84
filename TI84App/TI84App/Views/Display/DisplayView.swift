import SwiftUI

/// Routes display content to the active screen's view.
struct DisplayView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            switch appState.activeScreen {
            case .home:
                HomeScreenView()
            case .graph:
                GraphScreenView()
            case .table:
                TableScreenView()
            case .yEquals:
                YEqualsEditorView()
            case .window:
                WindowEditorView()
            case .mode:
                ModeScreenView()
            case .matrixEditor:
                MatrixEditorView()
            case .listEditor:
                ListEditorView()
            case .programEditor(let name):
                ProgramEditorView(programName: name)
            case .programIO:
                ProgramIOView()
            default:
                HomeScreenView()
            }

            // Menu overlay
            if appState.activeMenu != nil {
                MenuOverlayView()
            }

            // Error overlay
            if let error = appState.errorMessage {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(error)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(8)
                            .background(Color(red: 0.78, green: 0.82, blue: 0.72))
                            .border(Color.black, width: 2)
                        Spacer()
                    }
                    Text("1:Quit  2:Goto")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.black)
                    Spacer()
                }
            }
        }
    }
}
