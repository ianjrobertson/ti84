import Foundation
import TI84Core

/// TI-BASIC program interpreter.
/// Uses a flat indexed statement list to support Goto/Lbl jumping in/out of loops.
/// Runs asynchronously so the UI stays responsive.
public actor TIBasicInterpreter {
    private let state: CalculatorState
    private weak var ioDelegate: TIBasicIODelegate?
    private var statements: [TIBasicStatement] = []
    private var labelIndex: [String: Int] = [:]
    private var pc: Int = 0
    private var isCancelled = false

    public init(state: CalculatorState, ioDelegate: TIBasicIODelegate?) {
        self.state = state
        self.ioDelegate = ioDelegate
    }

    /// Run a program by name.
    public func run(programName: String) async throws {
        guard let source = await state.programs[programName] else {
            throw CalcError.undefined
        }
        try await execute(source: source)
    }

    /// Execute TI-BASIC source code.
    public func execute(source: String) async throws {
        let parser = TIBasicParser()
        statements = parser.parse(source)
        buildLabelIndex()
        pc = 0
        isCancelled = false

        while pc < statements.count && !isCancelled {
            try await executeStatement(statements[pc])
            pc += 1
        }
    }

    /// Cancel execution (from ON key press).
    public func cancel() {
        isCancelled = true
    }

    // MARK: - Label Index

    private func buildLabelIndex() {
        labelIndex = [:]
        for (i, stmt) in statements.enumerated() {
            if case .label(let name) = stmt {
                labelIndex[name] = i
            }
        }
    }

    // MARK: - Statement Execution

    private func executeStatement(_ stmt: TIBasicStatement) async throws {
        guard !isCancelled else { throw CalcError.breakProgram }

        switch stmt {
        case .expression(let expr):
            try await executeExpression(expr)

        case .disp(let exprs):
            for expr in exprs {
                let result = try await evaluateExpression(expr)
                let formatter = await TI84NumberFormatter(settings: state.modeSettings)
                await ioDelegate?.display(formatter.format(result))
            }

        case .output(let rowExpr, let colExpr, let valueExpr):
            let row = try await evaluateExpression(rowExpr)
            let col = try await evaluateExpression(colExpr)
            let value = try await evaluateExpression(valueExpr)
            guard let r = row.asInt, let c = col.asInt else { throw CalcError.dataType }
            let formatter = await TI84NumberFormatter(settings: state.modeSettings)
            await ioDelegate?.output(row: r, col: c, text: formatter.format(value))

        case .input(let prompt, let varName):
            let text = await ioDelegate?.input(prompt: prompt) ?? "0"
            let value = try await evaluateExpression(text)
            try await state.setVariable(varName, value)

        case .prompt(let varNames):
            for varName in varNames {
                let text = await ioDelegate?.input(prompt: "\(varName)=?") ?? "0"
                let value = try await evaluateExpression(text)
                try await state.setVariable(varName, value)
            }

        case .clrHome:
            await ioDelegate?.clearHome()

        case .ifThen(let condition):
            let result = try await evaluateExpression(condition)
            guard let val = result.asReal else { throw CalcError.dataType }
            if val == 0 {
                // Condition false: skip to matching Then/Else/End or next statement
                skipIfBlock()
            }

        case .then:
            break // Handled by ifThen

        case .elseStmt:
            // If we reach Else during normal execution, skip to End
            skipToEnd()

        case .end:
            break // Loop/If terminator, handled by loop logic

        case .forLoop(let varName, let startExpr, let endExpr, let stepExpr):
            let start = try await evaluateExpression(startExpr)
            let end = try await evaluateExpression(endExpr)
            let step = stepExpr != nil ? try await evaluateExpression(stepExpr!) : TI84Value.real(1)

            guard let startVal = start.asReal, let endVal = end.asReal, let stepVal = step.asReal else {
                throw CalcError.dataType
            }

            try await state.setVariable(varName, .real(startVal))
            let loopStart = pc

            while !isCancelled {
                let current = await state.getVariable(varName)?.asReal ?? startVal
                if (stepVal > 0 && current > endVal) || (stepVal < 0 && current < endVal) {
                    break
                }

                // Execute loop body
                pc = loopStart + 1
                while pc < statements.count {
                    if case .end = statements[pc] { break }
                    try await executeStatement(statements[pc])
                    pc += 1
                }

                // Increment
                let newVal = (await state.getVariable(varName)?.asReal ?? current) + stepVal
                try await state.setVariable(varName, .real(newVal))
            }

        case .whileLoop(let condition):
            let loopStart = pc

            while !isCancelled {
                let result = try await evaluateExpression(condition)
                guard let val = result.asReal else { throw CalcError.dataType }
                if val == 0 { break }

                pc = loopStart + 1
                while pc < statements.count {
                    if case .end = statements[pc] { break }
                    try await executeStatement(statements[pc])
                    pc += 1
                }
            }

        case .repeatLoop(let condition):
            let loopStart = pc

            var firstIteration = true
            while !isCancelled {
                if !firstIteration {
                    let result = try await evaluateExpression(condition)
                    guard let val = result.asReal else { throw CalcError.dataType }
                    if val != 0 { break } // Repeat exits when condition is TRUE
                }
                firstIteration = false

                pc = loopStart + 1
                while pc < statements.count {
                    if case .end = statements[pc] { break }
                    try await executeStatement(statements[pc])
                    pc += 1
                }
            }

        case .label:
            break // Labels are just markers

        case .goto(let name):
            guard let target = labelIndex[name] else {
                throw CalcError.labelNotFound(name)
            }
            pc = target - 1 // Will be incremented by main loop

        case .menu(let title, let items):
            guard let selectedLabel = await ioDelegate?.showMenu(title: title, items: items) else {
                return
            }
            guard let target = labelIndex[selectedLabel] else {
                throw CalcError.labelNotFound(selectedLabel)
            }
            pc = target - 1

        case .stop:
            pc = statements.count // End execution

        case .returnStmt:
            pc = statements.count // End current program

        case .pause(let expr):
            if let expr = expr {
                let result = try await evaluateExpression(expr)
                let formatter = await TI84NumberFormatter(settings: state.modeSettings)
                await ioDelegate?.pause(formatter.format(result))
            } else {
                await ioDelegate?.pause(nil)
            }

        case .getKey(let varName):
            let key = await ioDelegate?.getKey() ?? 0
            try await state.setVariable(varName, .real(Double(key)))

        case .prgmCall(let name):
            // Save PC and execute subroutine
            let savedPC = pc
            let savedStatements = statements
            try await run(programName: name)
            statements = savedStatements
            buildLabelIndex()
            pc = savedPC

        case .line(let x1, let y1, let x2, let y2):
            let vals = try await [x1, y1, x2, y2].asyncMap { try await evaluateExpression($0) }
            guard let x1v = vals[0].asReal, let y1v = vals[1].asReal,
                  let x2v = vals[2].asReal, let y2v = vals[3].asReal else { throw CalcError.dataType }
            await ioDelegate?.drawLine(x1: x1v, y1: y1v, x2: x2v, y2: y2v)

        case .circle(let x, let y, let r):
            let vals = try await [x, y, r].asyncMap { try await evaluateExpression($0) }
            guard let xv = vals[0].asReal, let yv = vals[1].asReal,
                  let rv = vals[2].asReal else { throw CalcError.dataType }
            await ioDelegate?.drawCircle(x: xv, y: yv, r: rv)

        case .text(let row, let col, let expr):
            let vals = try await [row, col].asyncMap { try await evaluateExpression($0) }
            let value = try await evaluateExpression(expr)
            guard let r = vals[0].asInt, let c = vals[1].asInt else { throw CalcError.dataType }
            let formatter = await TI84NumberFormatter(settings: state.modeSettings)
            await ioDelegate?.drawText(row: r, col: c, text: formatter.format(value))

        case .ptOn(let x, let y):
            let xVal = try await evaluateExpression(x)
            let yVal = try await evaluateExpression(y)
            guard let xv = xVal.asReal, let yv = yVal.asReal else { throw CalcError.dataType }
            await ioDelegate?.plotPoint(x: xv, y: yv, on: true)

        case .ptOff(let x, let y):
            let xVal = try await evaluateExpression(x)
            let yVal = try await evaluateExpression(y)
            guard let xv = xVal.asReal, let yv = yVal.asReal else { throw CalcError.dataType }
            await ioDelegate?.plotPoint(x: xv, y: yv, on: false)

        case .clrDraw:
            await ioDelegate?.clearDraw()

        case .storedExpression(let expr, let varName):
            let value = try await evaluateExpression(expr)
            try await state.setVariable(varName, value)
        }
    }

    // MARK: - Expression Evaluation

    private func evaluateExpression(_ expr: String) async throws -> TI84Value {
        let parser = try Parser(expression: expr)
        let ast = try parser.parse()
        let evaluator = Evaluator(context: state)
        return try evaluator.evaluate(ast)
    }

    private func executeExpression(_ expr: String) async throws {
        let result = try await evaluateExpression(expr)
        await MainActor.run {
            state.ans = result
        }
    }

    // MARK: - Control Flow Helpers

    private func skipIfBlock() {
        var depth = 0
        pc += 1
        while pc < statements.count {
            switch statements[pc] {
            case .then, .forLoop, .whileLoop, .repeatLoop:
                depth += 1
            case .elseStmt where depth == 0:
                return // Continue execution after Else
            case .end:
                if depth == 0 { return }
                depth -= 1
            default:
                break
            }
            pc += 1
        }
    }

    private func skipToEnd() {
        var depth = 0
        pc += 1
        while pc < statements.count {
            switch statements[pc] {
            case .then, .forLoop, .whileLoop, .repeatLoop:
                depth += 1
            case .end:
                if depth == 0 { return }
                depth -= 1
            default:
                break
            }
            pc += 1
        }
    }
}

// MARK: - Async Helper

private extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var results: [T] = []
        results.reserveCapacity(count)
        for element in self {
            results.append(try await transform(element))
        }
        return results
    }
}
