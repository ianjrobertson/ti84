import SwiftUI

/// Blinking cursor for the calculator display.
struct CursorView: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: 8, height: 16)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}
