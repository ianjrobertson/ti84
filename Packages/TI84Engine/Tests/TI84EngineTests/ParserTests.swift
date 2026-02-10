import XCTest
@testable import TI84Engine
@testable import TI84Core

final class ParserTests: XCTestCase {
    func testSimpleAddition() throws {
        let parser = try Parser(expression: "2+3")
        let ast = try parser.parse()
        XCTAssertEqual(ast, .binary(.add, .number(2), .number(3)))
    }

    func testOperatorPrecedence() throws {
        let parser = try Parser(expression: "2+3*4")
        let ast = try parser.parse()
        XCTAssertEqual(ast, .binary(.add, .number(2), .binary(.multiply, .number(3), .number(4))))
    }

    func testPowerRightAssociative() throws {
        let parser = try Parser(expression: "2^3^4")
        let ast = try parser.parse()
        XCTAssertEqual(ast, .binary(.power, .number(2), .binary(.power, .number(3), .number(4))))
    }

    func testNegation() throws {
        // -3^2 should be -(3^2) = -9 on TI-84
        let parser = try Parser(expression: "-3^2")
        let ast = try parser.parse()
        XCTAssertEqual(ast, .unaryPrefix(.negate, .binary(.power, .number(3), .number(2))))
    }

    func testFunctionCall() throws {
        let parser = try Parser(expression: "sin(3.14)")
        let ast = try parser.parse()
        XCTAssertEqual(ast, .functionCall(.sin, [.number(3.14)]))
    }

    func testImplicitMultiplication() throws {
        let parser = try Parser(expression: "2(3)")
        let ast = try parser.parse()
        // Should parse as 2 * 3
        if case .binary(.multiply, .number(2), .number(3)) = ast {
            // correct
        } else {
            XCTFail("Expected 2*(3), got \(ast)")
        }
    }

    func testListLiteral() throws {
        let parser = try Parser(expression: "{1,2,3}")
        let ast = try parser.parse()
        XCTAssertEqual(ast, .listLiteral([.number(1), .number(2), .number(3)]))
    }
}
