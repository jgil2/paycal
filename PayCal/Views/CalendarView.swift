import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var items: [PayCalItem]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month Header Navigation
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(currentMonth.formatted(.dateTime.month().year()))
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Calendar Grid
                let days = daysInMonth()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .bold()
                            .foregroundColor(.secondary)
                    }

                    ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate), hasItems: hasItemsOn(date)) {
                                selectedDate = date
                            }
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Selected Day Items List
                VStack(alignment: .leading) {
                    Text("Due on \(selectedDate.formatted(date: .long, time: .omitted))")
                        .font(.headline)
                        .padding(.horizontal)

                    let selectedItems = itemsDueOn(selectedDate)
                    if selectedItems.isEmpty {
                        ContentUnavailableView("No Items Due", systemImage: "checkmark.circle", description: Text("Clear schedule for this day."))
                    } else {
                        List(selectedItems, id: \.item.id) { display in
                            HStack {
                                Text(display.item.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(display.item.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                    .foregroundColor(display.item.type.isIncome ? .green : .red)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Calendar View")
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let totalDays = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func hasItemsOn(_ date: Date) -> Bool {
        return !itemsDueOn(date).isEmpty
    }

    private func itemsDueOn(_ date: Date) -> [(item: PayCalItem, date: Date)] {
        let calendar = Calendar.current
        var matching: [(item: PayCalItem, date: Date)] = []

        for item in items {
            let occurrences = item.nextOccurrences(limit: 12, relativeTo: calendar.date(byAdding: .month, value: -1, to: Date())!)
            for occ in occurrences {
                if calendar.isDate(occ, inSameDayAs: date) {
                    matching.append((item, occ))
                }
            }
        }
        return matching
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasItems: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.body)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)

                Circle()
                    .fill(hasItems ? (isSelected ? .white : Color.emerald) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.emerald : Color.clear)
            .cornerRadius(8)
        }
    }
}
