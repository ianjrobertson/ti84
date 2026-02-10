import XCTest
@testable import TI84Core

final class TI84CoreTests: XCTestCase {
    func testTI84ValueReal() {
        let val = TI84Value.real(3.14)
        XCTAssertEqual(val.asReal, 3.14)
        XCTAssertNil(val.asMatrix)
    }

    func testTI84ValueList() {
        let val = TI84Value.list([1, 2, 3])
        XCTAssertEqual(val.asList, [1, 2, 3])
    }

    func testCalcKeyDigit() {
        XCTAssertTrue(CalcKey.num5.isDigit)
        XCTAssertEqual(CalcKey.num5.digitValue, 5)
        XCTAssertFalse(CalcKey.sin.isDigit)
    }

    func testCalcKeyAlpha() {
        XCTAssertEqual(CalcKey.math.alphaCharacter, "A")
        XCTAssertEqual(CalcKey.store.alphaCharacter, "X")
    }
}
