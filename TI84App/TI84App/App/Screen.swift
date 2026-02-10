import Foundation

/// All screens the calculator can display.
enum Screen: Equatable {
    case home
    case graph
    case table
    case yEquals
    case window
    case windowFormat
    case tableSetup
    case mode
    case listEditor
    case matrixEditor
    case programEditor(String?)   // program name or nil for new
    case programIO
    case catalog
    case statPlot
    case statEditor
    case draw
    case error(String)

    var title: String {
        switch self {
        case .home: return "Home"
        case .graph: return "Graph"
        case .table: return "Table"
        case .yEquals: return "Y="
        case .window: return "Window"
        case .windowFormat: return "Format"
        case .tableSetup: return "Table Setup"
        case .mode: return "Mode"
        case .listEditor: return "List Editor"
        case .matrixEditor: return "Matrix Editor"
        case .programEditor: return "Program Editor"
        case .programIO: return "Program I/O"
        case .catalog: return "Catalog"
        case .statPlot: return "Stat Plot"
        case .statEditor: return "Stat Editor"
        case .draw: return "Draw"
        case .error(let msg): return msg
        }
    }
}
