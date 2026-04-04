import SwiftUI

struct MonthGridView: View {
    @Bindable var viewModel: CalendarViewModel

    private let weekdaySymbols = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = Locale(identifier: "de_DE")
        cal.firstWeekday = 2
        return cal
    }

    private var gridDays: [GridDay] {
        let cal = calendar
        let comps = cal.dateComponents([.year, .month], from: viewModel.currentMonth)
        guard let firstOfMonth = cal.date(from: comps),
              let monthRange = cal.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let offsetFromMonday = (firstWeekday + 5) % 7

        var days: [GridDay] = []

        for i in 0..<offsetFromMonday {
            if let date = cal.date(byAdding: .day, value: -(offsetFromMonday - i), to: firstOfMonth) {
                days.append(GridDay(date: date, isCurrentMonth: false))
            }
        }

        for day in monthRange {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(GridDay(date: date, isCurrentMonth: true))
            }
        }

        let remaining = (7 - days.count % 7) % 7
        if let lastOfMonth = days.last?.date {
            for i in 1...max(remaining, 7) {
                if days.count >= 42 { break }
                if let date = cal.date(byAdding: .day, value: i, to: lastOfMonth) {
                    days.append(GridDay(date: date, isCurrentMonth: false))
                }
            }
        }

        while days.count < 42 {
            if let last = days.last?.date,
               let next = cal.date(byAdding: .day, value: 1, to: last) {
                days.append(GridDay(date: next, isCurrentMonth: false))
            }
        }

        return days
    }

    var body: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.appSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(gridDays) { gridDay in
                    DayCellView(
                        gridDay: gridDay,
                        isSelected: calendar.isDate(gridDay.date, inSameDayAs: viewModel.selectedDate),
                        isToday: calendar.isDateInToday(gridDay.date),
                        eventDots: dotsForDate(gridDay.date)
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.selectedDate = gridDay.date
                        }
                    }
                }
            }
        }
    }

    private func dotsForDate(_ date: Date) -> [Color] {
        let events = viewModel.eventsForDate(date)
        let colors = events.prefix(3).map { event -> Color in
            if let cat = event.category {
                return Color(hex: cat.color)
            }
            return .appPrimary
        }
        return colors
    }
}

// MARK: - Grid Day Model

private struct GridDay: Identifiable {
    let date: Date
    let isCurrentMonth: Bool

    var id: String { date.isoDateString }
}

// MARK: - Day Cell

private struct DayCellView: View {
    let gridDay: GridDay
    let isSelected: Bool
    let isToday: Bool
    let eventDots: [Color]

    private var dayNumber: Int {
        Calendar.current.component(.day, from: gridDay.date)
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .strokeBorder(Color.appPrimary, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }

                Text("\(dayNumber)")
                    .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(foregroundColor)
            }
            .frame(height: 32)

            HStack(spacing: 3) {
                ForEach(Array(eventDots.enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var foregroundColor: Color {
        if isSelected { return .white }
        if !gridDay.isCurrentMonth { return .appSecondary.opacity(0.5) }
        return .primary
    }
}
