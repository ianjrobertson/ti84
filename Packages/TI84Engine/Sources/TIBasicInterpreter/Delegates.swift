import Foundation
import TI84Core

/// Protocol for TI-BASIC program I/O interactions with the UI.
public protocol TIBasicIODelegate: AnyObject, Sendable {
    /// Display a value on the home screen.
    func display(_ text: String) async

    /// Display text at a specific row/col position.
    func output(row: Int, col: Int, text: String) async

    /// Request input from the user with optional prompt.
    func input(prompt: String?) async -> String

    /// Pause execution (wait for ENTER).
    func pause(_ text: String?) async

    /// getKey — wait for and return a key code.
    func getKey() async -> Int

    /// Clear the home screen.
    func clearHome() async

    /// Show a menu and return the selected label.
    func showMenu(title: String, items: [(String, String)]) async -> String

    /// Draw a line on the graph screen.
    func drawLine(x1: Double, y1: Double, x2: Double, y2: Double) async

    /// Draw a circle on the graph screen.
    func drawCircle(x: Double, y: Double, r: Double) async

    /// Draw text on the graph screen.
    func drawText(row: Int, col: Int, text: String) async

    /// Plot a point on the graph screen.
    func plotPoint(x: Double, y: Double, on: Bool) async

    /// Clear all drawings.
    func clearDraw() async
}
