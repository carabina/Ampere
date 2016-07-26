import Ampere
import XCTest

/// Tests for the base functionality of `UnitProduct`.
///
/// - Multiplication and division operations.
/// - Correct mapping from between input units and result unit.
class UnitProductTests: XCTestCase {

    func testMultiplicationWithDefaultUnitMapping() {
        let speed = Measurement<SpeedDummy>(value: 10, unit: .metersPerSecond)
        let time = Measurement<DurationDummy>(value: 5, unit: .seconds)
        let length: Measurement<LengthDummy> = speed * time
        let expected = Measurement<LengthDummy>(value: 50, unit: .meters)
        XCTAssertTrue(length == expected)
    }

    func testMultiplicationIsCommutative() {
        let speed = Measurement<SpeedDummy>(value: 10, unit: .metersPerSecond)
        let time = Measurement<DurationDummy>(value: 5, unit: .seconds)
        let length1: Measurement<LengthDummy> = speed * time
        let length2: Measurement<LengthDummy> = time * speed
        XCTAssertTrue(length1 == length2)
    }

    func testMultiplicationUsesPreferredUnitMapping() {
        let speed = Measurement<SpeedDummy>(value: 32, unit: .kilometersPerHour)
        let time = Measurement<DurationDummy>(value: 2, unit: .hours)
        let length: Measurement<LengthDummy> = speed * time
        let expected = Measurement<LengthDummy>(value: 64, unit: .kilometers)
        XCTAssertTrue(length == expected)
        XCTAssertTrue(length.unit === expected.unit)
    }

    func testMultiplicationFallsBackToDefaultUnitMapping() {
        let speed = Measurement<SpeedDummy>(value: 32, unit: .kilometersPerHour)
        let time = Measurement<DurationDummy>(value: 3600, unit: .seconds)
        let length: Measurement<LengthDummy> = speed * time
        let expected = Measurement<LengthDummy>(value: 32, unit: .kilometers)
        // XCTAssertEqual(length, expected) would be preferable, but that assertions fails for reasons I can't explain (Xcode 8 beta 3).
        XCTAssertTrue(length == expected)
        XCTAssertTrue(length.unit === LengthDummy.meters)
    }

    func testDivisionByFirstFactor() {
        let length = Measurement<LengthDummy>(value: 20, unit: .meters)
        let speed = Measurement<SpeedDummy>(value: 10, unit: .metersPerSecond)
        let time = length / speed
        let expected = Measurement<DurationDummy>(value: 2, unit: .seconds)
        XCTAssertTrue(time == expected)
    }

    func testDivisionBySecondFactor() {
        let length = Measurement<LengthDummy>(value: 20, unit: .meters)
        let time = Measurement<DurationDummy>(value: 5, unit: .seconds)
        let speed = length / time
        let expected = Measurement<SpeedDummy>(value: 4, unit: .metersPerSecond)
        XCTAssertTrue(speed == expected)
    }

    func testDivisionByFirstFactorUsesPreferredUnitMapping() {
        let length = Measurement<LengthDummy>(value: 500, unit: .kilometers)
        let speed = Measurement<SpeedDummy>(value: 125, unit: .kilometersPerHour)
        let time = length / speed
        let expected = Measurement<DurationDummy>(value: 4, unit: .hours)
        XCTAssertTrue(time == expected)
        XCTAssertTrue(time.unit === expected.unit)
    }

    func testDivisionBySecondFactorUsesPreferredUnitMapping() {
        let length = Measurement<LengthDummy>(value: 20, unit: .kilometers)
        let time = Measurement<DurationDummy>(value: 5, unit: .hours)
        let speed = length / time
        let expected = Measurement<SpeedDummy>(value: 4, unit: .kilometersPerHour)
        XCTAssertTrue(speed == expected)
        XCTAssertTrue(speed.unit === expected.unit)
    }

}


// MARK: - Dummy types that adopt `UnitProduct`.
// Define some dummy `Dimension` subclasses that adopt `UnitProduct` for the tests. This way we don’t mix the base functionality tests with the actual implementations of the protocol conformance for the "real" `Unit…` types.

class LengthDummy: Dimension {
    /// Base unit: meters
    override class func baseUnit() -> LengthDummy { return .meters }
    static let meters = LengthDummy(symbol: "m", converter: UnitConverterLinear(coefficient: 1))
    static let kilometers = LengthDummy(symbol: "km", converter: UnitConverterLinear(coefficient: 1000))
}

class DurationDummy: Dimension {
    /// Base unit: seconds
    override class func baseUnit() -> DurationDummy { return .seconds }
    static let seconds = DurationDummy(symbol: "s", converter: UnitConverterLinear(coefficient: 1))
    static let hours = DurationDummy(symbol: "h", converter: UnitConverterLinear(coefficient: 3600))
}

class SpeedDummy: Dimension {
    /// Base unit: meters per second
    override class func baseUnit() -> SpeedDummy { return .metersPerSecond }
    static let metersPerSecond = SpeedDummy(symbol: "m/s", converter: UnitConverterLinear(coefficient: 1))
    static let kilometersPerHour = SpeedDummy(symbol: "km/h", converter: UnitConverterLinear(coefficient: 1.0/3.6))
}

// velocity = distance / time ⇔ distance = velocity * time
// Speed = Length / Duration ⇔ Length = Speed * Duration
extension LengthDummy: UnitProduct {
    typealias Factor1 = SpeedDummy
    typealias Factor2 = DurationDummy
    typealias Product = LengthDummy

    static func defaultUnitMapping() -> (Factor1, Factor2, Product) {
        return (.metersPerSecond, .seconds, .meters)
    }

    static func unitMappings() -> [(Factor1, Factor2, Product)] {
        return [
            (.kilometersPerHour, .hours, .kilometers)
        ]
    }
}