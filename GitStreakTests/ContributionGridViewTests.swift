import XCTest
import SwiftUI
@testable import GitStreakKit

final class ContributionGridViewTests: XCTestCase {
    func testDayLabelsCountAndOrder() {
        let labels = ContributionDayLabelsView.dayLabels
        XCTAssertEqual(labels.count, 7, "Contribution grid week must have exactly 7 rows")

        // Order: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
        // First row: Sunday (nil / no label)
        XCTAssertNil(labels[0], "Row 0 (Sunday) must have no label")

        // Second row: Monday ("M")
        XCTAssertEqual(labels[1], "M", "Row 1 (Monday) must be 'M' on the second row")

        // Third row: Tuesday (nil / no label)
        XCTAssertNil(labels[2], "Row 2 (Tuesday) must have no label")

        // Fourth row: Wednesday ("W")
        XCTAssertEqual(labels[3], "W", "Row 3 (Wednesday) must be 'W' on the fourth row")

        // Fifth row: Thursday (nil / no label)
        XCTAssertNil(labels[4], "Row 4 (Thursday) must have no label")

        // Sixth row: Friday ("F")
        XCTAssertEqual(labels[5], "F", "Row 5 (Friday) must be 'F' on the sixth row")

        // Seventh row: Saturday (nil / no label)
        XCTAssertNil(labels[6], "Row 6 (Saturday) must have no label")
    }

    func testOnlyMondayWednesdayFridayAreLabeled() {
        let nonNilLabels = ContributionDayLabelsView.dayLabels.compactMap { $0 }
        XCTAssertEqual(nonNilLabels, ["M", "W", "F"], "Only M, W, and F should be displayed")
    }
}
