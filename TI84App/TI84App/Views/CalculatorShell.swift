import SwiftUI
import TI84Core

/// Main calculator window: display area on top, keypad on bottom.
struct CalculatorShell: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            StatusBarView()
                .frame(height: 20)

            // Display area
            DisplayView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.78, green: 0.82, blue: 0.72)) // LCD green
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 12)
                .padding(.top, 4)

            // Keypad
            KeypadView()
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .onKeyDown { event in
            if let key = KeyboardShortcutHandler.mapKeyEvent(event) {
                appState.handleKey(key)
            }
        }
    }
}

// MARK: - Key Event Handling

struct KeyEventHandlingView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}

class KeyCaptureView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}

extension View {
    func onKeyDown(handler: @escaping (NSEvent) -> Void) -> some View {
        background(
            KeyEventHandlingView(onKeyDown: handler)
                .frame(width: 0, height: 0)
        )
    }
}
