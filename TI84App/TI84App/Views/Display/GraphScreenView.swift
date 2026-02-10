import SwiftUI
import TI84Core
import TI84Engine

/// Graph screen: Canvas-based function plotter with trace cursor.
struct GraphScreenView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let window = appState.calculatorState.windowParameters
                let viewWidth = size.width
                let viewHeight = size.height

                // Draw background
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .color(Color.white))

                // Draw grid
                drawGrid(context: context, size: size, window: window)

                // Draw axes
                drawAxes(context: context, size: size, window: window)

                // Draw functions
                drawFunctions(context: context, size: size, window: window)

                // Draw trace cursor
                if appState.graphVM.isTracing {
                    drawTraceCursor(context: context, size: size, window: window)
                }
            }
            .overlay(alignment: .top) {
                // Function label during trace
                if appState.graphVM.isTracing {
                    traceOverlay
                }
            }
        }
    }

    // MARK: - Grid

    private func drawGrid(context: GraphicsContext, size: CGSize, window: WindowParameters) {
        guard appState.calculatorState.showGrid else { return }

        let gridColor = Color.gray.opacity(0.3)

        // Vertical grid lines
        var x = ceil(window.xMin / window.xScl) * window.xScl
        while x <= window.xMax {
            let (vx, _) = FunctionPlotter.mathToView(x: x, y: 0, window: window,
                                                      viewWidth: Double(size.width),
                                                      viewHeight: Double(size.height))
            let path = Path { p in
                p.move(to: CGPoint(x: vx, y: 0))
                p.addLine(to: CGPoint(x: vx, y: Double(size.height)))
            }
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            x += window.xScl
        }

        // Horizontal grid lines
        var y = ceil(window.yMin / window.yScl) * window.yScl
        while y <= window.yMax {
            let (_, vy) = FunctionPlotter.mathToView(x: 0, y: y, window: window,
                                                      viewWidth: Double(size.width),
                                                      viewHeight: Double(size.height))
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: vy))
                p.addLine(to: CGPoint(x: Double(size.width), y: vy))
            }
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            y += window.yScl
        }
    }

    // MARK: - Axes

    private func drawAxes(context: GraphicsContext, size: CGSize, window: WindowParameters) {
        guard appState.calculatorState.showAxes else { return }

        let axisColor = Color.black

        // X axis
        let (_, yAxisPos) = FunctionPlotter.mathToView(x: 0, y: 0, window: window,
                                                        viewWidth: Double(size.width),
                                                        viewHeight: Double(size.height))
        if yAxisPos >= 0 && yAxisPos <= Double(size.height) {
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: yAxisPos))
                p.addLine(to: CGPoint(x: Double(size.width), y: yAxisPos))
            }
            context.stroke(path, with: .color(axisColor), lineWidth: 1)

            // X tick marks
            var x = ceil(window.xMin / window.xScl) * window.xScl
            while x <= window.xMax {
                let (vx, _) = FunctionPlotter.mathToView(x: x, y: 0, window: window,
                                                          viewWidth: Double(size.width),
                                                          viewHeight: Double(size.height))
                let tick = Path { p in
                    p.move(to: CGPoint(x: vx, y: yAxisPos - 3))
                    p.addLine(to: CGPoint(x: vx, y: yAxisPos + 3))
                }
                context.stroke(tick, with: .color(axisColor), lineWidth: 1)
                x += window.xScl
            }
        }

        // Y axis
        let (xAxisPos, _) = FunctionPlotter.mathToView(x: 0, y: 0, window: window,
                                                        viewWidth: Double(size.width),
                                                        viewHeight: Double(size.height))
        if xAxisPos >= 0 && xAxisPos <= Double(size.width) {
            let path = Path { p in
                p.move(to: CGPoint(x: xAxisPos, y: 0))
                p.addLine(to: CGPoint(x: xAxisPos, y: Double(size.height)))
            }
            context.stroke(path, with: .color(axisColor), lineWidth: 1)

            // Y tick marks
            var y = ceil(window.yMin / window.yScl) * window.yScl
            while y <= window.yMax {
                let (_, vy) = FunctionPlotter.mathToView(x: 0, y: y, window: window,
                                                          viewWidth: Double(size.width),
                                                          viewHeight: Double(size.height))
                let tick = Path { p in
                    p.move(to: CGPoint(x: xAxisPos - 3, y: vy))
                    p.addLine(to: CGPoint(x: xAxisPos + 3, y: vy))
                }
                context.stroke(tick, with: .color(axisColor), lineWidth: 1)
                y += window.yScl
            }
        }
    }

    // MARK: - Functions

    private func drawFunctions(context: GraphicsContext, size: CGSize, window: WindowParameters) {
        let colors: [Color] = [.blue, .red, .green, .purple, .orange, .cyan, .brown, .pink, .indigo, .teal]

        for i in 0..<10 {
            let yNum = i == 9 ? 0 : i + 1
            guard appState.calculatorState.isYVarEnabled(yNum),
                  !appState.calculatorState.yVarExpression(yNum).isEmpty else { continue }

            let evaluator: (Double) -> Double? = { [weak appState] x in
                try? appState?.calculatorState.evaluateYVar(yNum, x: x)
            }

            let segments = FunctionPlotter.plot(
                evaluator: evaluator,
                window: window,
                pixelWidth: Int(size.width)
            )

            let color = colors[i % colors.count]

            for segment in segments {
                guard segment.points.count >= 2 else { continue }
                var path = Path()
                let first = segment.points[0]
                let (fx, fy) = FunctionPlotter.mathToView(x: first.x, y: first.y,
                                                           window: window,
                                                           viewWidth: Double(size.width),
                                                           viewHeight: Double(size.height))
                path.move(to: CGPoint(x: fx, y: fy))

                for point in segment.points.dropFirst() {
                    let (px, py) = FunctionPlotter.mathToView(x: point.x, y: point.y,
                                                               window: window,
                                                               viewWidth: Double(size.width),
                                                               viewHeight: Double(size.height))
                    path.addLine(to: CGPoint(x: px, y: py))
                }

                context.stroke(path, with: .color(color), lineWidth: 2)
            }
        }
    }

    // MARK: - Trace Cursor

    private func drawTraceCursor(context: GraphicsContext, size: CGSize, window: WindowParameters) {
        let x = appState.graphVM.traceX
        let y = appState.graphVM.traceY

        let (vx, vy) = FunctionPlotter.mathToView(x: x, y: y, window: window,
                                                    viewWidth: Double(size.width),
                                                    viewHeight: Double(size.height))

        // Crosshair
        let crossSize = 8.0
        let crossPath = Path { p in
            p.move(to: CGPoint(x: vx - crossSize, y: vy))
            p.addLine(to: CGPoint(x: vx + crossSize, y: vy))
            p.move(to: CGPoint(x: vx, y: vy - crossSize))
            p.addLine(to: CGPoint(x: vx, y: vy + crossSize))
        }
        context.stroke(crossPath, with: .color(.black), lineWidth: 1.5)

        // Dot
        let dotRect = CGRect(x: vx - 3, y: vy - 3, width: 6, height: 6)
        context.fill(Path(ellipseIn: dotRect), with: .color(.black))
    }

    // MARK: - Trace Overlay

    private var traceOverlay: some View {
        VStack(alignment: .leading, spacing: 2) {
            let yNum = appState.graphVM.traceFunctionIndex
            Text("Y\(yNum)=\(appState.calculatorState.yVarExpression(yNum))")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.black)

            HStack {
                Text("X=\(formatTraceValue(appState.graphVM.traceX))")
                Spacer()
                Text("Y=\(formatTraceValue(appState.graphVM.traceY))")
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.black)
        }
        .padding(4)
        .background(Color.white.opacity(0.85))
    }

    private func formatTraceValue(_ value: Double) -> String {
        let formatter = TI84NumberFormatter(settings: appState.calculatorState.modeSettings)
        return formatter.formatReal(value)
    }
}
