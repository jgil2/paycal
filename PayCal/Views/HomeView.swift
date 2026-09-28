import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PayCalItem.dueDate, order: .forward) private var items: [PayCalItem]
    
    @State private var showingAddItem = false
    @State private var itemToEdit: PayCalItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 30-Day Financial Summary Card
                    SummaryCard(paycheckTotal: totalsNext30Days.paychecks, billTotal: totalsNext30Days.bills)
                        .padding(.horizontal)

                    // Upcoming Items Grouped by Week
                    if groupedUpcomingItems.isEmpty {
                        ContentUnavailableView("No Upcoming Items", systemImage: "tray", description: Text("Tap '+' to add paychecks or bills."))
                            .padding(.top, 40)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(groupedUpcomingItems, id: \.0) { groupTitle, groupItems in
                                Section(header: Text(groupTitle).font(.headline).foregroundColor(.secondary).padding(.horizontal)) {
                                    ForEach(groupItems, id: \.item.id) { displayItem in
                                        ItemRow(item: displayItem.item, occurrenceDate: displayItem.date)
                                            .padding(.horizontal)
                                            .contextMenu {
                                                Button(action: { itemToEdit = displayItem.item }) {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                Button(role: .destructive, action: { deleteItem(displayItem.item) }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("PayCal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditItemView()
            }
            .sheet(item: $itemToEdit) { item in
                AddEditItemView(itemToEdit: item)
            }
        }
    }

    struct DisplayItem {
        let item: PayCalItem
        let date: Date
    }

    private var groupedUpcomingItems: [(String, [DisplayItem])] {
        let now = Date()
        var allDisplayItems: [DisplayItem] = []

        for item in items {
            let occurrences = item.nextOccurrences(limit: 3, relativeTo: now)
            for occ in occurrences {
                allDisplayItems.append(DisplayItem(item: item, date: occ))
            }
        }

        allDisplayItems.sort { $0.date < $1.date }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allDisplayItems) { displayItem -> String in
            if calendar.isDateInToday(displayItem.date) {
                return "Today"
            } else if calendar.isDateInTomorrow(displayItem.date) {
                return "Tomorrow"
            } else {
                let weekOfYear = calendar.component(.weekOfYear, from: displayItem.date)
                let year = calendar.component(.year, from: displayItem.date)
                return "Week of \(calendar.date(from: DateComponents(year: year, weekOfYear: weekOfYear))?.formatted(date: .abbreviated, time: .omitted) ?? "")"
            }
        }

        return grouped.sorted { lhs, rhs in
            guard let firstL = lhs.1.first?.date, let firstR = rhs.1.first?.date else { return false }
            return firstL < firstR
        }
    }

    private var totalsNext30Days: (paychecks: Double, bills: Double) {
        let now = Date()
        guard let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: now) else {
            return (0, 0)
        }

        var paychecks = 0.0
        var bills = 0.0

        for item in items {
            let occurrences = item.nextOccurrences(limit: 5, relativeTo: now)
            for occ in occurrences where occ >= Calendar.current.startOfDay(for: now) && occ <= thirtyDaysLater {
                if item.type.isIncome {
                    paychecks += item.amount
                } else {
                    bills += item.amount
                }
            }
        }

        return (paychecks, bills)
    }

    private func deleteItem(_ item: PayCalItem) {
        modelContext.delete(item)
        try? modelContext.save()
        NotificationManager.shared.rescheduleAllNotifications(context: modelContext)
    }
}

struct SummaryCard: View {
    let paycheckTotal: Double
    let billTotal: Double

    var netBalance: Double { paycheckTotal - billTotal }

    var body: some View {
        VStack(spacing: 12) {
            Text("NEXT 30 DAYS SUMMARY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading) {
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(paycheckTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Bills")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(billTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3)
                        .bold()
                        .foregroundColor(.red)
                }
            }

            Divider()

            HStack {
                Text("Net Expected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(netBalance, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.headline)
                    .bold()
                    .foregroundColor(netBalance >= 0 ? .primary : .red)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct ItemRow: View {
    let item: PayCalItem
    let occurrenceDate: Date

    var body: some View {
        HStack {
            Circle()
                .fill(item.type.isIncome ? Color.green : Color.red)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(occurrenceDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.callout)
                .bold()
                .foregroundColor(item.type.isIncome ? .green : .primary)
        }
        .padding()
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(12)
    }
}
