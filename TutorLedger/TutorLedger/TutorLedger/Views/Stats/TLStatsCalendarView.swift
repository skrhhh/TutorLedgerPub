import SwiftUI

struct TLStatsCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDay: Date
    let lessonDays: Set<Date>

    private var calendar: Calendar { .autoupdatingCurrent }

    private var weekdays: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday
        return (0..<7).map { symbols[($0 + first - 1) % 7] }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { shiftMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TLColors.teal)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Text(monthTitle)
                    .font(.headline)
                    .foregroundStyle(TLColors.primaryText)
                    .frame(maxWidth: .infinity)

                Button { shiftMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TLColors.teal)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TLColors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(gridDays, id: \.id) { item in
                    if let date = item.date {
                        dayButton(date, isCurrentMonth: item.isCurrentMonth)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }

    private var monthTitle: String {
        TLDateFormat.yearMonth(displayedMonth)
    }

    private struct GridDay: Identifiable {
        let id: String
        let date: Date?
        let isCurrentMonth: Bool
    }

    private var gridDays: [GridDay] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let leadingPads = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        var items: [GridDay] = []

        for index in 0..<leadingPads {
            items.append(GridDay(id: "pad-start-\(index)", date: nil, isCurrentMonth: false))
        }

        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                items.append(GridDay(id: "day-\(day)", date: date, isCurrentMonth: true))
            }
        }

        while items.count % 7 != 0 {
            items.append(GridDay(id: "pad-end-\(items.count)", date: nil, isCurrentMonth: false))
        }

        return items
    }

    @ViewBuilder
    private func dayButton(_ date: Date, isCurrentMonth: Bool) -> some View {
        let dayStart = calendar.startOfDay(for: date)
        let isSelected = calendar.isDate(dayStart, inSameDayAs: selectedDay)
        let isToday = calendar.isDateInToday(date)
        let hasLessons = lessonDays.contains(dayStart)

        Button {
            selectedDay = dayStart
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(dayNumberColor(isSelected: isSelected, isCurrentMonth: isCurrentMonth))
                    .frame(width: 34, height: 34)
                    .background {
                        if isSelected {
                            Circle().fill(TLColors.breezeGradient)
                        } else if isToday {
                            Circle()
                                .strokeBorder(TLColors.teal.opacity(0.45), lineWidth: 1.5)
                        }
                    }

                Circle()
                    .fill(TLColors.pending)
                    .frame(width: 5, height: 5)
                    .opacity(hasLessons ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .opacity(isCurrentMonth ? 1 : 0.35)
    }

    private func dayNumberColor(isSelected: Bool, isCurrentMonth: Bool) -> Color {
        if isSelected { return .white }
        if isCurrentMonth { return TLColors.primaryText }
        return TLColors.secondaryText
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = newMonth

        if !calendar.isDate(selectedDay, equalTo: newMonth, toGranularity: .month) {
            selectedDay = calendar.startOfDay(for: newMonth)
        }
    }
}
