import XCTest
import SwiftUI
@testable import GitStreakKit

final class ThemeRegistryTests: XCTestCase {

    func testDefaultThemeIsGitHub() {
        let theme = ThemeRegistry.defaultTheme
        XCTAssertEqual(theme.id, "github")
        XCTAssertEqual(theme.name, "GitHub")
    }

    func testLookupExistingTheme() {
        let ocean = ThemeRegistry.theme(for: "ocean")
        XCTAssertEqual(ocean.id, "ocean")
        XCTAssertEqual(ocean.name, "Ocean")
    }

    func testLookupUnknownThemeFallsBackToDefault() {
        let fallback = ThemeRegistry.theme(for: "non_existent_theme_id")
        XCTAssertEqual(fallback.id, ThemeRegistry.defaultTheme.id)
    }

    func testAllThemesAvailableFreely() {
        let all = ThemeRegistry.allThemes
        XCTAssertEqual(all.count, 5)
        XCTAssertEqual(ThemeRegistry.freeThemes.count, 5)
        XCTAssertFalse(all.contains { $0.id == "monochrome" })
        XCTAssertTrue(all.contains { $0.id == "nord" })
        XCTAssertTrue(all.contains { $0.id == "forest" })
    }

    func testThemeColorsAllLevels() {
        let theme = ThemeRegistry.github
        XCTAssertEqual(theme.allColors.count, 5)

        _ = theme.color(for: .none)
        _ = theme.color(for: .firstQuartile)
        _ = theme.color(for: .secondQuartile)
        _ = theme.color(for: .thirdQuartile)
        _ = theme.color(for: .fourthQuartile)
    }

    func testLightModeEmptyBlockColor() {
        let theme = ThemeRegistry.github
        let expectedLightColor = Color(hex: "#EFF2F5")
        XCTAssertEqual(theme.color(for: .none, colorScheme: .light, isWidget: false), expectedLightColor)
        XCTAssertEqual(theme.color(for: .none, colorScheme: .light, isWidget: true), expectedLightColor)
    }

    func testDarkModeWidgetEmptyBlockColor() {
        let theme = ThemeRegistry.github
        let expectedDarkWidgetColor = Color(hex: "#2C2C2C")
        XCTAssertEqual(theme.color(for: .none, colorScheme: .dark, isWidget: true), expectedDarkWidgetColor)
    }

    func testColorSchemeContributionColorsInversion() {
        let theme = ThemeRegistry.github

        // Light mode: higher activity = darker color
        XCTAssertEqual(theme.color(for: .firstQuartile, colorScheme: .light), Color(hex: theme.lowHex))
        XCTAssertEqual(theme.color(for: .secondQuartile, colorScheme: .light), Color(hex: theme.mediumHex))
        XCTAssertEqual(theme.color(for: .thirdQuartile, colorScheme: .light), Color(hex: theme.highHex))
        XCTAssertEqual(theme.color(for: .fourthQuartile, colorScheme: .light), Color(hex: theme.veryHighHex))

        // Dark mode: GitHub uses explicit high-contrast palette
        XCTAssertEqual(theme.color(for: .firstQuartile, colorScheme: .dark), Color(hex: "#023A16"))
        XCTAssertEqual(theme.color(for: .secondQuartile, colorScheme: .dark), Color(hex: "#006D32"))
        XCTAssertEqual(theme.color(for: .thirdQuartile, colorScheme: .dark), Color(hex: "#26A641"))
        XCTAssertEqual(theme.color(for: .fourthQuartile, colorScheme: .dark), Color(hex: "#39D353"))

        // Swatch lists reflect the scheme order
        let lightColors = theme.allColors(for: .light)
        XCTAssertEqual(lightColors, [
            Color(hex: "#EFF2F5"),
            Color(hex: theme.lowHex),
            Color(hex: theme.mediumHex),
            Color(hex: theme.highHex),
            Color(hex: theme.veryHighHex)
        ])

        let darkColors = theme.allColors(for: .dark)
        XCTAssertEqual(darkColors, [
            Color(hex: "#2C2C2C"),
            Color(hex: "#023A16"),
            Color(hex: "#006D32"),
            Color(hex: "#26A641"),
            Color(hex: "#39D353")
        ])
    }
}
