import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var items: [PayCalItem]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false
    @State private var itemToEdit: PayCalItem?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Next 30 Days Summary") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Paychecks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(totals.paychecks, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Bills & Subs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(totals.bills, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                ForEach(groupedItems, id: \.key) { weekLabel, weekItems in
                    Section(weekLabel) {
                        ForEach(weekItems) { item in
                            HStack {
                                Button {
                                    item.isPaid.toggle()
                                } label: {
                                    Image(systemName: item.isPaid ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(item.isPaid ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                ItemIconView(iconName: item.iconName, itemType: item.type)
                                
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                        .strikethrough(item.isPaid, color: .secondary)
                                        .foregroundStyle(item.isPaid ? .secondary : .primary)
                                    
                                    if let nextDate = item.nextDueDate() {
                                        Text(nextDate, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(item.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                    .font(.subheadline)
                                    .bold()
                                    .strikethrough(item.isPaid, color: .secondary)
                                    .foregroundStyle(item.type == .paycheck ? .green : (item.isPaid ? .secondary : .primary))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                itemToEdit = item
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, from: weekItems)
                        }
                    }
                }
            }
            .navigationTitle("PayCal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditItemView()
            }
            .sheet(item: $itemToEdit) { item in
                AddEditItemView(itemToEdit: item)
            }
        }
    }
    
    private var totals: (paychecks: Double, bills: Double) {
        let now = Date()
        let thirtyDaysOut = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        
        var totalPay = 0.0
        var totalBills = 0.0
        
        for item in items {
            let dates = item.nextOccurrences(count: 10, from: now).filter { $0 <= thirtyDaysOut }
            for _ in dates {
                if item.type == .paycheck {
                    totalPay += item.amount
                } else {
                    totalBills += item.amount
                }
            }
        }
        return (totalPay, totalBills)
    }
    
    private var groupedItems: [(key: String, value: [PayCalItem])] {
        let calendar = Calendar.current
        let now = Date()
        
        let validItems = items.compactMap { item -> (PayCalItem, Date)? in
            guard let next = item.nextDueDate(after: now) else { return nil }
            return (item, next)
        }.sorted { $0.1 < $1.1 }
        
        var groups: [String: [PayCalItem]] = [:]
        for (item, date) in validItems {
            let weekNumber = calendar.component(.weekOfYear, from: date)
            let currentWeek = calendar.component(.weekOfYear, from: now)
            
            let key: String
            if weekNumber == currentWeek {
                key = "This Week"
            } else if weekNumber == currentWeek + 1 {
                key = "Next Week"
            } else {
                key = "In \(weekNumber - currentWeek) Weeks"
            }
            
            groups[key, default: []].append(item)
        }
        
        return groups.map { ($0.key, $0.value) }
    }
    
    private func color(for type: ItemType) -> Color {
        switch type {
        case .paycheck: return .green
        case .bill: return .red
        case .subscription: return .purple
        }
    }
    
    private func deleteItems(at offsets: IndexSet, from list: [PayCalItem]) {
        for index in offsets {
            let item = list[index]
            modelContext.delete(item)
        }
        Task {
            let fetchDescriptor = FetchDescriptor<PayCalItem>()
            if let allItems = try? modelContext.fetch(fetchDescriptor) {
                await NotificationManager.shared.scheduleNotifications(for: allItems)
            }
        }
    }
}