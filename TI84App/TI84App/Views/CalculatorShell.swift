import SwiftUI
import AppKit
import TI84Core

// MARK: - TI-84 Color Palette (matched to real hardware)

private enum TI84Colors {
    static let body = Color(red: 0.10, green: 0.10, blue: 0.16)
    static let bodyEdge = Color(red: 0.06, green: 0.06, blue: 0.10)
    static let faceplate = Color(red: 0.14, green: 0.14, blue: 0.20)
    static let screenBezel = Color(red: 0.60, green: 0.62, blue: 0.64)
    static let screenBezelInner = Color(red: 0.40, green: 0.42, blue: 0.44)
    static let lcd = Color(red: 0.76, green: 0.80, blue: 0.70)
    static let lcdDark = Color(red: 0.70, green: 0.74, blue: 0.64)

    // Button colors matching real TI-84 Plus
    static let btnBlueFunc = Color(red: 0.22, green: 0.33, blue: 0.56)
    static let btnYellow = Color(red: 0.90, green: 0.75, blue: 0.10)
    static let btnGreen = Color(red: 0.20, green: 0.58, blue: 0.32)
    static let btnDark = Color(red: 0.22, green: 0.22, blue: 0.26)
    static let btnBlack = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let btnEnter = Color(red: 0.16, green: 0.24, blue: 0.50)
    static let btnDPad = Color(red: 0.20, green: 0.20, blue: 0.24)

    // Label colors
    static let labelYellow = Color(red: 0.90, green: 0.78, blue: 0.15)
    static let labelGreen = Color(red: 0.30, green: 0.75, blue: 0.40)
    static let labelWhite = Color.white
    static let labelBlack = Color.black

    // Branding
    static let tiBlue = Color(red: 0.20, green: 0.40, blue: 0.72)
}

// MARK: - Main Calculator Shell

struct CalculatorShell: View {
    @EnvironmentObject var appState: AppState
    @State private var eventMonitor: Any? = nil

    // Reference dimensions — everything is proportional to these
    private let calcWidth: CGFloat = 380
    private let calcHeight: CGFloat = 820

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / calcWidth, geo.size.height / calcHeight)

            ZStack {
                // Calculator body
                calculatorBody(scale: scale)
            }
            .frame(width: calcWidth * scale, height: calcHeight * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        }
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if let responder = event.window?.firstResponder,
                   responder is NSTextView {
                    return event
                }
                if let key = KeyboardShortcutHandler.mapKeyEvent(event) {
                    appState.handleKey(key)
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }

    // MARK: - Calculator Body

    @ViewBuilder
    private func calculatorBody(scale: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Outer body shell
            RoundedRectangle(cornerRadius: 24 * scale)
                .fill(
                    LinearGradient(
                        colors: [TI84Colors.body, TI84Colors.bodyEdge],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)

            VStack(spacing: 0) {
                // Top branding area
                brandingArea(scale: scale)

                // Screen
                screenArea(scale: scale)

                Spacer().frame(height: 10 * scale)

                // Top function keys row (Y=, WINDOW, ZOOM, TRACE, GRAPH)
                functionKeyRow(scale: scale)

                Spacer().frame(height: 6 * scale)

                // 2nd, MODE, DEL, ALPHA, X,T,θ,n row
                modifierKeyRow(scale: scale)

                Spacer().frame(height: 10 * scale)

                // D-Pad
                dPad(scale: scale)

                Spacer().frame(height: 10 * scale)

                // Main keypad rows
                mainKeypad(scale: scale)

                Spacer().frame(height: 8 * scale)
            }
            .padding(.horizontal, 16 * scale)
        }
        .frame(width: calcWidth * scale, height: calcHeight * scale)
    }

    // MARK: - Branding

    @ViewBuilder
    private func brandingArea(scale: CGFloat) -> some View {
        VStack(spacing: 2 * scale) {
            Spacer().frame(height: 12 * scale)

            Text("TEXAS INSTRUMENTS")
                .font(.system(size: 8 * scale, weight: .medium))
                .tracking(2 * scale)
                .foregroundColor(.gray.opacity(0.6))

            HStack(spacing: 4 * scale) {
                Text("TI-84 Plus")
                    .font(.system(size: 14 * scale, weight: .bold))
                    .foregroundColor(TI84Colors.tiBlue)
                Spacer()
            }
            .padding(.leading, 4 * scale)

            Spacer().frame(height: 4 * scale)
        }
    }

    // MARK: - Screen Area

    @ViewBuilder
    private func screenArea(scale: CGFloat) -> some View {
        ZStack {
            // Outer bezel
            RoundedRectangle(cornerRadius: 8 * scale)
                .fill(
                    LinearGradient(
                        colors: [TI84Colors.screenBezel, TI84Colors.screenBezelInner],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200 * scale)

            // Inner screen inset
            ZStack {
                // LCD background with subtle pixel grid effect
                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(TI84Colors.lcd)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)

                // Status bar + display content
                VStack(spacing: 0) {
                    // Status bar inside screen
                    HStack(spacing: 6 * scale) {
                        if appState.secondActive {
                            Text("2nd")
                                .font(.system(size: 8 * scale, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        if appState.alphaLock {
                            Text("A-LOCK")
                                .font(.system(size: 8 * scale, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.7))
                        } else if appState.alphaActive {
                            Text("ALPHA")
                                .font(.system(size: 8 * scale, weight: .bold, design: .monospaced))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        Spacer()
                        Text(appState.calculatorState.modeSettings.angleUnit == .radian ? "RAD" : "DEG")
                            .font(.system(size: 8 * scale, design: .monospaced))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .frame(height: 14 * scale)
                    .padding(.horizontal, 4 * scale)

                    // Main display
                    DisplayView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(8 * scale)
            .frame(height: 200 * scale)
        }
    }

    // MARK: - Function Key Row (Y=, WINDOW, ZOOM, TRACE, GRAPH)

    @ViewBuilder
    private func functionKeyRow(scale: CGFloat) -> some View {
        let keys = keypadRows[0]
        VStack(spacing: 0) {
            // 2nd labels above
            HStack(spacing: 4 * scale) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, kd in
                    Text(kd.secondLabel ?? "")
                        .font(.system(size: 7 * scale, weight: .medium))
                        .foregroundColor(TI84Colors.labelYellow)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(height: 11 * scale)

            HStack(spacing: 4 * scale) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, kd in
                    ti84Button(kd, scale: scale, style: .function)
                }
            }
        }
    }

    // MARK: - Modifier Key Row (2nd, MODE, DEL, ALPHA, X,T,θ,n)

    @ViewBuilder
    private func modifierKeyRow(scale: CGFloat) -> some View {
        let keys = keypadRows[1]
        VStack(spacing: 0) {
            HStack(spacing: 4 * scale) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, kd in
                    Text(kd.secondLabel ?? "")
                        .font(.system(size: 7 * scale, weight: .medium))
                        .foregroundColor(TI84Colors.labelYellow)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(height: 11 * scale)

            HStack(spacing: 4 * scale) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, kd in
                    ti84Button(kd, scale: scale, style: .modifier)
                }
            }
        }
    }

    // MARK: - D-Pad

    @ViewBuilder
    private func dPad(scale: CGFloat) -> some View {
        let padSize: CGFloat = 110 * scale
        ZStack {
            // Circular background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [TI84Colors.btnDPad.opacity(0.9), TI84Colors.btnDPad.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: padSize / 2
                    )
                )
                .frame(width: padSize, height: padSize)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)

            // Up
            Button(action: { appState.handleKey(.up) }) {
                dPadArrow("▲", scale: scale)
            }
            .buttonStyle(.plain)
            .offset(y: -28 * scale)

            // Down
            Button(action: { appState.handleKey(.down) }) {
                dPadArrow("▼", scale: scale)
            }
            .buttonStyle(.plain)
            .offset(y: 28 * scale)

            // Left
            Button(action: { appState.handleKey(.left) }) {
                dPadArrow("◀", scale: scale)
            }
            .buttonStyle(.plain)
            .offset(x: -28 * scale)

            // Right
            Button(action: { appState.handleKey(.right) }) {
                dPadArrow("▶", scale: scale)
            }
            .buttonStyle(.plain)
            .offset(x: 28 * scale)

            // Center ring
            Circle()
                .stroke(TI84Colors.btnDPad.opacity(0.3), lineWidth: 1)
                .frame(width: 20 * scale, height: 20 * scale)
        }
    }

    @ViewBuilder
    private func dPadArrow(_ symbol: String, scale: CGFloat) -> some View {
        Text(symbol)
            .font(.system(size: 14 * scale, weight: .bold))
            .foregroundColor(.white.opacity(0.8))
            .frame(width: 32 * scale, height: 32 * scale)
            .contentShape(Rectangle())
    }

    // MARK: - Main Keypad

    @ViewBuilder
    private func mainKeypad(scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Rows 3-9 (indices 2..8 in keypadRows)
            ForEach(2..<keypadRows.count, id: \.self) { rowIdx in
                let keys = keypadRows[rowIdx]

                VStack(spacing: 0) {
                    // 2nd / ALPHA labels above buttons
                    HStack(spacing: 4 * scale) {
                        ForEach(Array(keys.enumerated()), id: \.offset) { _, kd in
                            VStack(spacing: 0) {
                                Text(kd.secondLabel ?? "")
                                    .font(.system(size: 7 * scale, weight: .medium))
                                    .foregroundColor(TI84Colors.labelYellow)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.4)

                                Text(kd.alphaLabel ?? "")
                                    .font(.system(size: 7 * scale, weight: .medium))
                                    .foregroundColor(TI84Colors.labelGreen)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 16 * scale)
                        }
                    }

                    // Buttons
                    HStack(spacing: 4 * scale) {
                        ForEach(Array(keys.enumerated()), id: \.offset) { _, kd in
                            ti84Button(kd, scale: scale, style: buttonStyle(for: kd))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Button Rendering

    private enum ButtonStyle {
        case function   // Blue top-row keys
        case modifier   // 2nd, ALPHA, etc.
        case standard   // Most keys
        case number     // Number keys (darker, rounder)
        case enter      // Enter key
        case accent     // Yellow/Green special keys
    }

    private func buttonStyle(for kd: KeyDef) -> ButtonStyle {
        switch kd.color {
        case .blue: return .function
        case .yellow, .green: return .accent
        case .black: return .number
        case .enter: return .enter
        default: return .standard
        }
    }

    @ViewBuilder
    private func ti84Button(_ kd: KeyDef, scale: CGFloat, style: ButtonStyle) -> some View {
        let bgColor = buttonColor(kd.color)
        let h: CGFloat = (style == .function) ? 24 : 30
        let radius: CGFloat = (style == .number) ? 10 : 6

        Button(action: {
            appState.handleKey(kd.key)
        }) {
            ZStack {
                // Button shape with 3D effect
                RoundedRectangle(cornerRadius: radius * scale)
                    .fill(
                        LinearGradient(
                            colors: [
                                bgColor.opacity(1.2),
                                bgColor,
                                bgColor.opacity(0.8),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius * scale)
                            .stroke(bgColor.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 2 * scale, x: 0, y: 2 * scale)

                // Primary label
                Text(kd.primary)
                    .font(.system(size: primaryFontSize(kd, scale: scale), weight: .semibold, design: .rounded))
                    .foregroundColor(kd.color.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .padding(.horizontal, 2 * scale)
            }
            .frame(maxWidth: .infinity)
            .frame(height: h * scale)
        }
        .buttonStyle(TI84ButtonPressStyle())
    }

    private func buttonColor(_ color: KeyColor) -> Color {
        switch color {
        case .blue: return TI84Colors.btnBlueFunc
        case .yellow: return TI84Colors.btnYellow
        case .green: return TI84Colors.btnGreen
        case .black: return TI84Colors.btnBlack
        case .enter: return TI84Colors.btnEnter
        case .dark: return TI84Colors.btnDark
        case .light: return Color(red: 0.45, green: 0.45, blue: 0.48)
        case .white: return Color(red: 0.65, green: 0.65, blue: 0.68)
        }
    }

    private func primaryFontSize(_ kd: KeyDef, scale: CGFloat) -> CGFloat {
        let len = kd.primary.count
        if len <= 2 { return 13 * scale }
        if len <= 4 { return 10 * scale }
        if len <= 6 { return 8.5 * scale }
        return 7 * scale
    }
}

// MARK: - Button Press Style

struct TI84ButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .offset(y: configuration.isPressed ? 1 : 0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}
