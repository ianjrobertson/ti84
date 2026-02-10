import Foundation
import TI84Core

/// A TI-BASIC statement.
public enum TIBasicStatement: Sendable {
    case expression(String)              // Evaluate and display (or store)
    case disp([String])                  // Disp expr[, expr...]
    case output(String, String, String)  // Output(row, col, expr)
    case input(String?, String)          // Input ["prompt",]var
    case prompt([String])                // Prompt var[, var...]
    case clrHome                         // ClrHome
    case ifThen(String)                  // If condition
    case then                            // Then
    case elseStmt                        // Else
    case end                             // End
    case forLoop(String, String, String, String?) // For(var, start, end[, step])
    case whileLoop(String)               // While condition
    case repeatLoop(String)              // Repeat condition
    case label(String)                   // Lbl label
    case goto(String)                    // Goto label
    case menu(String, [(String, String)]) // Menu("title","item1","label1",...)
    case stop                            // Stop
    case returnStmt                      // Return
    case pause(String?)                  // Pause [expr]
    case getKey(String)                  // getKey→var
    case prgmCall(String)               // prgmNAME
    case line(String, String, String, String) // Line(x1,y1,x2,y2)
    case circle(String, String, String)  // Circle(x,y,r)
    case text(String, String, String)    // Text(row,col,expr)
    case ptOn(String, String)            // Pt-On(x,y)
    case ptOff(String, String)           // Pt-Off(x,y)
    case clrDraw                         // ClrDraw
    case storedExpression(String, String) // expr→var
}

/// Parses TI-BASIC program text into a flat list of statements.
public struct TIBasicParser {
    public init() {}

    public func parse(_ source: String) -> [TIBasicStatement] {
        var statements: [TIBasicStatement] = []

        // Split by newlines and colons (TI-BASIC line separator)
        let lines = source.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Split by : (colon is statement separator in TI-BASIC)
            let parts = splitByColons(trimmed)

            for part in parts {
                let stmt = part.trimmingCharacters(in: .whitespaces)
                if stmt.isEmpty { continue }
                if let parsed = parseStatement(stmt) {
                    statements.append(parsed)
                }
            }
        }

        return statements
    }

    private func splitByColons(_ line: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var inString = false

        for ch in line {
            if ch == "\"" { inString.toggle() }
            if ch == ":" && !inString {
                parts.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { parts.append(current) }
        return parts
    }

    private func parseStatement(_ stmt: String) -> TIBasicStatement? {
        // Control flow
        if stmt.hasPrefix("If ") {
            return .ifThen(String(stmt.dropFirst(3)))
        }
        if stmt == "Then" { return .then }
        if stmt == "Else" { return .elseStmt }
        if stmt == "End" { return .end }

        if stmt.hasPrefix("For(") {
            let inner = extractParens(stmt, prefix: "For")
            let parts = splitArgs(inner)
            guard parts.count >= 3 else { return nil }
            return .forLoop(parts[0], parts[1], parts[2], parts.count > 3 ? parts[3] : nil)
        }

        if stmt.hasPrefix("While ") {
            return .whileLoop(String(stmt.dropFirst(6)))
        }

        if stmt.hasPrefix("Repeat ") {
            return .repeatLoop(String(stmt.dropFirst(7)))
        }

        if stmt.hasPrefix("Lbl ") {
            return .label(String(stmt.dropFirst(4)).trimmingCharacters(in: .whitespaces))
        }

        if stmt.hasPrefix("Goto ") {
            return .goto(String(stmt.dropFirst(5)).trimmingCharacters(in: .whitespaces))
        }

        // I/O
        if stmt.hasPrefix("Disp ") {
            let args = splitArgs(String(stmt.dropFirst(5)))
            return .disp(args)
        }

        if stmt.hasPrefix("Output(") {
            let inner = extractParens(stmt, prefix: "Output")
            let parts = splitArgs(inner)
            guard parts.count >= 3 else { return nil }
            return .output(parts[0], parts[1], parts[2])
        }

        if stmt.hasPrefix("Input ") {
            let rest = String(stmt.dropFirst(6))
            if rest.contains(",") {
                let parts = splitArgs(rest)
                guard parts.count >= 2 else { return nil }
                return .input(parts[0], parts[1])
            }
            return .input(nil, rest.trimmingCharacters(in: .whitespaces))
        }

        if stmt.hasPrefix("Prompt ") {
            let args = splitArgs(String(stmt.dropFirst(7)))
            return .prompt(args)
        }

        if stmt == "ClrHome" { return .clrHome }
        if stmt == "ClrDraw" { return .clrDraw }
        if stmt == "Stop" { return .stop }
        if stmt == "Return" { return .returnStmt }

        if stmt.hasPrefix("Pause") {
            if stmt.count > 5 {
                return .pause(String(stmt.dropFirst(6)))
            }
            return .pause(nil)
        }

        if stmt.hasPrefix("Menu(") {
            return parseMenu(stmt)
        }

        if stmt.hasPrefix("prgm") {
            return .prgmCall(String(stmt.dropFirst(4)))
        }

        // Draw commands
        if stmt.hasPrefix("Line(") {
            let inner = extractParens(stmt, prefix: "Line")
            let parts = splitArgs(inner)
            guard parts.count >= 4 else { return nil }
            return .line(parts[0], parts[1], parts[2], parts[3])
        }

        if stmt.hasPrefix("Circle(") {
            let inner = extractParens(stmt, prefix: "Circle")
            let parts = splitArgs(inner)
            guard parts.count >= 3 else { return nil }
            return .circle(parts[0], parts[1], parts[2])
        }

        if stmt.hasPrefix("Text(") {
            let inner = extractParens(stmt, prefix: "Text")
            let parts = splitArgs(inner)
            guard parts.count >= 3 else { return nil }
            return .text(parts[0], parts[1], parts[2])
        }

        if stmt.hasPrefix("Pt-On(") {
            let inner = extractParens(stmt, prefix: "Pt-On")
            let parts = splitArgs(inner)
            guard parts.count >= 2 else { return nil }
            return .ptOn(parts[0], parts[1])
        }

        if stmt.hasPrefix("Pt-Off(") {
            let inner = extractParens(stmt, prefix: "Pt-Off")
            let parts = splitArgs(inner)
            guard parts.count >= 2 else { return nil }
            return .ptOff(parts[0], parts[1])
        }

        // Default: expression (may include store →)
        return .expression(stmt)
    }

    private func parseMenu(_ stmt: String) -> TIBasicStatement? {
        let inner = extractParens(stmt, prefix: "Menu")
        let parts = splitArgs(inner)
        guard parts.count >= 3, parts.count % 2 == 1 else { return nil }
        let title = parts[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        var items: [(String, String)] = []
        var i = 1
        while i + 1 < parts.count {
            let label = parts[i].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let lbl = parts[i + 1].trimmingCharacters(in: .whitespaces)
            items.append((label, lbl))
            i += 2
        }
        return .menu(title, items)
    }

    private func extractParens(_ stmt: String, prefix: String) -> String {
        let start = stmt.index(stmt.startIndex, offsetBy: prefix.count + 1)
        var end = stmt.endIndex
        if stmt.hasSuffix(")") {
            end = stmt.index(before: end)
        }
        return String(stmt[start..<end])
    }

    private func splitArgs(_ str: String) -> [String] {
        var args: [String] = []
        var current = ""
        var depth = 0
        var inString = false

        for ch in str {
            if ch == "\"" { inString.toggle() }
            if !inString {
                if ch == "(" { depth += 1 }
                if ch == ")" { depth -= 1 }
                if ch == "," && depth == 0 {
                    args.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                    continue
                }
            }
            current.append(ch)
        }
        if !current.isEmpty {
            args.append(current.trimmingCharacters(in: .whitespaces))
        }
        return args
    }
}
