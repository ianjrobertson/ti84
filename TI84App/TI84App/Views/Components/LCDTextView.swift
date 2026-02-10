import SwiftUI

/// LCD-styled monospace text matching the TI-84 display.
struct LCDTextView: View {
    let text: String
    var size: CGFloat = 16

    var body: some View {
        Text(text)
            .font(.system(size: size, design: .monospaced))
            .foregroundColor(.black)
    }
}
