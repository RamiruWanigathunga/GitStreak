import SwiftUI

public struct ContributionGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let weeks: [ContributionWeek]
    public let theme: ThemeColors
    public let maxWeeks: Int
    public let cellSize: CGFloat
    public let cellSpacing: CGFloat
    public let columnSpacing: CGFloat?
    public let rowSpacing: CGFloat?
    public let cornerRadius: CGFloat?
    public let showMonthHeaders: Bool
    public let showDayLabels: Bool
    public let showTooltips: Bool
    public let isWidget: Bool

    public init(
        weeks: [ContributionWeek],
        theme: ThemeColors = ThemeRegistry.defaultTheme,
        maxWeeks: Int = 13,
        cellSize: CGFloat = GSSpacing.gridCellSize,
        cellSpacing: CGFloat = GSSpacing.gridCellSpacing,
        columnSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        showMonthHeaders: Bool = false,
        showDayLabels: Bool = false,
        showTooltips: Bool = false,
        isWidget: Bool = false
    ) {
        self.weeks = weeks
        self.theme = theme
        self.maxWeeks = maxWeeks
        self.cellSize = cellSize
        self.cellSpacing = cellSpacing
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
        self.cornerRadius = cornerRadius
        self.showMonthHeaders = showMonthHeaders
        self.showDayLabels = showDayLabels
        self.showTooltips = showTooltips
        self.isWidget = isWidget
    }

    public var body: some View {
        let displayWeeks = Array(weeks.suffix(maxWeeks))
        let colSpacing = columnSpacing ?? cellSpacing
        let rSpacing = rowSpacing ?? cellSpacing

        HStack(spacing: colSpacing) {
            if showDayLabels {
                ContributionDayLabelsView(
                    cellSize: cellSize,
                    rowSpacing: rSpacing,
                    showMonthHeaders: showMonthHeaders
                )
            }

            ForEach(Array(displayWeeks.enumerated()), id: \.offset) { weekIdx, week in
                ContributionWeekColumnView(
                    week: week,
                    weekIndex: weekIdx,
                    totalWeeks: displayWeeks.count,
                    monthLabel: monthLabel(for: weekIdx, in: displayWeeks),
                    rSpacing: rSpacing,
                    cellSize: cellSize,
                    theme: theme,
                    cornerRadius: cornerRadius,
                    showMonthHeaders: showMonthHeaders,
                    showTooltips: showTooltips,
                    colorScheme: colorScheme,
                    isWidget: isWidget
                )
            }
        }
    }

    private func monthLabel(for weekIndex: Int, in displayWeeks: [ContributionWeek]) -> String? {
        guard weekIndex < displayWeeks.count, let firstDayStr = displayWeeks[weekIndex].contributionDays.first?.date else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: firstDayStr) else {
            return nil
        }

        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)

        if weekIndex == 0 {
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            return monthFormatter.string(from: date)
        }

        if let prevFirstDayStr = displayWeeks[weekIndex - 1].contributionDays.first?.date,
           let prevDate = formatter.date(from: prevFirstDayStr) {
            let prevMonth = calendar.component(.month, from: prevDate)
            if month != prevMonth {
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMM"
                return monthFormatter.string(from: date)
            }
        }

        return nil
    }
}

private struct ContributionWeekColumnView: View {
    let week: ContributionWeek
    let weekIndex: Int
    let totalWeeks: Int
    let monthLabel: String?
    let rSpacing: CGFloat
    let cellSize: CGFloat
    let theme: ThemeColors
    let cornerRadius: CGFloat?
    let showMonthHeaders: Bool
    let showTooltips: Bool
    let colorScheme: ColorScheme
    let isWidget: Bool

    @State private var isColumnHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: rSpacing) {
            if showMonthHeaders {
                Color.clear
                    .frame(width: cellSize, height: 14)
                    .overlay(alignment: .leading) {
                        if let label = monthLabel {
                            Text(label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .fixedSize()
                        }
                    }
            }

            ForEach(0..<7, id: \.self) { dayIndex in
                if dayIndex < week.contributionDays.count {
                    let day = week.contributionDays[dayIndex]
                    let cellColor = theme.color(for: day.level, colorScheme: colorScheme, isWidget: isWidget)
                    let radius = cornerRadius ?? max(1.0, cellSize * 0.2)
                    let strokeColor = isWidget
                        ? Color.clear
                        : (colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.14))

                    ContributionGridCellView(
                        day: day,
                        dayIndex: dayIndex,
                        weekIndex: weekIndex,
                        totalWeeks: totalWeeks,
                        cellColor: cellColor,
                        radius: radius,
                        strokeColor: strokeColor,
                        cellSize: cellSize,
                        showTooltips: showTooltips,
                        isWidget: isWidget
                    )
                } else {
                    Color.clear
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .zIndex(isColumnHovered ? 9999 : 1)
        .onHover { hovering in
            isColumnHovered = hovering
        }
    }
}

private struct ContributionGridCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    let day: ContributionDay
    let dayIndex: Int
    let weekIndex: Int
    let totalWeeks: Int
    let cellColor: Color
    let radius: CGFloat
    let strokeColor: Color
    let cellSize: CGFloat
    let showTooltips: Bool
    let isWidget: Bool

    @State private var isHovered = false
    @State private var hoverTask: Task<Void, Never>? = nil

    var body: some View {
        let isRightHalf = weekIndex >= (totalWeeks / 2)
        let isTopRow = dayIndex < 3

        let tooltipAlignment: Alignment = {
            if isTopRow {
                return isRightHalf ? .topTrailing : .topLeading
            } else {
                return isRightHalf ? .bottomTrailing : .bottomLeading
            }
        }()

        let yOffset: CGFloat = isTopRow ? 20 : -20
        let xOffset: CGFloat = isRightHalf ? -12 : 12

        RoundedRectangle(cornerRadius: radius)
            .fill(cellColor)
            .overlay(
                Group {
                    if !isWidget {
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(isHovered ? (colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.8)) : strokeColor, lineWidth: isHovered ? 1.2 : 0.5)
                    }
                }
            )
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .shadow(color: isHovered ? Color.black.opacity(0.15) : Color.clear, radius: 2, x: 0, y: 1)
            .overlay(alignment: tooltipAlignment) {
                if isHovered && showTooltips {
                    VStack(spacing: 2) {
                        Text("\(day.contributionCount) contributions")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        Text(day.date)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.80))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#1E1E1E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                    )
                    .offset(x: xOffset, y: yOffset)
                    .fixedSize()
                    .allowsHitTesting(false)
                }
            }
            .zIndex(isHovered ? 9999 : 1)
            .frame(width: cellSize, height: cellSize)
            .onHover { hovering in
                guard showTooltips else { return }
                hoverTask?.cancel()
                if hovering {
                    hoverTask = Task {
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        if !Task.isCancelled {
                            await MainActor.run {
                                withAnimation(.easeOut(duration: 0.12)) {
                                    isHovered = true
                                }
                            }
                        }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.1)) {
                        isHovered = false
                    }
                }
            }
    }
}

public struct ContributionDayLabelsView: View {
    public let cellSize: CGFloat
    public let rowSpacing: CGFloat
    public let showMonthHeaders: Bool
    public let monthHeaderHeight: CGFloat
    public let font: Font
    public let textColor: Color

    public init(
        cellSize: CGFloat = GSSpacing.gridCellSize,
        rowSpacing: CGFloat = GSSpacing.gridCellSpacing,
        showMonthHeaders: Bool = true,
        monthHeaderHeight: CGFloat = 14,
        font: Font = GSTypography.monoBadge,
        textColor: Color = .secondary
    ) {
        self.cellSize = cellSize
        self.rowSpacing = rowSpacing
        self.showMonthHeaders = showMonthHeaders
        self.monthHeaderHeight = monthHeaderHeight
        self.font = font
        self.textColor = textColor
    }

    /// Days of the week in standard contribution calendar order starting from Sunday:
    /// Row 0 (index 0): Sunday -> hidden / blank
    /// Row 1 (index 1): Monday -> "M"
    /// Row 2 (index 2): Tuesday -> hidden / blank
    /// Row 3 (index 3): Wednesday -> "W"
    /// Row 4 (index 4): Thursday -> hidden / blank
    /// Row 5 (index 5): Friday -> "F"
    /// Row 6 (index 6): Saturday -> hidden / blank
    public static let dayLabels: [String?] = [
        nil,  // Sunday (Row 0)
        "M",  // Monday (Row 1)
        nil,  // Tuesday (Row 2)
        "W",  // Wednesday (Row 3)
        nil,  // Thursday (Row 4)
        "F",  // Friday (Row 5)
        nil   // Saturday (Row 6)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            if showMonthHeaders {
                Text(" ")
                    .font(font)
                    .frame(height: monthHeaderHeight)
                    .hidden()
            }

            ForEach(0..<7, id: \.self) { dayIndex in
                if let label = Self.dayLabels[dayIndex] {
                    Text(label)
                        .font(font)
                        .foregroundColor(textColor)
                        .frame(height: cellSize)
                } else {
                    Text(" ")
                        .font(font)
                        .frame(height: cellSize)
                        .hidden()
                }
            }
        }
    }
}

