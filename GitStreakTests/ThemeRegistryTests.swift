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
        let expectedDarkWidgetColor = Color(hex: "#151B23")
        XCTAssertEqual(theme.color(for: .none, colorScheme: .dark, isWidget: true), expectedDarkWidgetColor)
    }

    func testColorSchemeContributionColorsInversion() {
        let ocean = ThemeRegistry.ocean

        // Light mode: higher activity = darker color
        XCTAssertEqual(ocean.color(for: .firstQuartile, colorScheme: .light), Color(hex: ocean.lowHex))
        XCTAssertEqual(ocean.color(for: .secondQuartile, colorScheme: .light), Color(hex: ocean.mediumHex))
        XCTAssertEqual(ocean.color(for: .thirdQuartile, colorScheme: .light), Color(hex: ocean.highHex))
        XCTAssertEqual(ocean.color(for: .fourthQuartile, colorScheme: .light), Color(hex: ocean.veryHighHex))

        // Dark mode without dedicated dark palette: higher activity = lighter color (inverted)
        XCTAssertEqual(ocean.color(for: .firstQuartile, colorScheme: .dark), Color(hex: ocean.veryHighHex))
        XCTAssertEqual(ocean.color(for: .secondQuartile, colorScheme: .dark), Color(hex: ocean.highHex))
        XCTAssertEqual(ocean.color(for: .thirdQuartile, colorScheme: .dark), Color(hex: ocean.mediumHex))
        XCTAssertEqual(ocean.color(for: .fourthQuartile, colorScheme: .dark), Color(hex: ocean.lowHex))

        // GitHub theme uses dedicated high-contrast dark palette
        let github = ThemeRegistry.github
        XCTAssertEqual(github.color(for: .firstQuartile, colorScheme: .dark), Color(hex: "#023A16"))
        XCTAssertEqual(github.color(for: .secondQuartile, colorScheme: .dark), Color(hex: "#006D32"))
        XCTAssertEqual(github.color(for: .thirdQuartile, colorScheme: .dark), Color(hex: "#26A641"))
        XCTAssertEqual(github.color(for: .fourthQuartile, colorScheme: .dark), Color(hex: "#39D353"))

        // Swatch lists reflect the scheme order
        let lightColors = github.allColors(for: .light)
        XCTAssertEqual(lightColors, [
            Color(hex: "#EFF2F5"),
            Color(hex: github.lowHex),
            Color(hex: github.mediumHex),
            Color(hex: github.highHex),
            Color(hex: github.veryHighHex)
        ])

        let darkColors = github.allColors(for: .dark)
        XCTAssertEqual(darkColors, [
            Color(hex: "#2C2C2C"),
            Color(hex: "#023A16"),
            Color(hex: "#006D32"),
            Color(hex: "#26A641"),
            Color(hex: "#39D353")
        ])
    }
}
