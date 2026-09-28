import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var items: [PayCalItem]
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                List {
                    Section("Items for Selected Date") {
                        let dayItems = itemsOnSelectedDate
                        if dayItems.isEmpty {
                            Text("No items due on this day.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(dayItems) { item in
                                HStack {
                                    ItemIconView(iconName: item.iconName, itemType: item.type)
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        Text(item.type.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(item.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                        .bold()
                                        .foregroundStyle(item.type.isIncome ? .green : .primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }
    
    private var itemsOnSelectedDate: [PayCalItem] {
        let calendar = Calendar.current
        return items.filter { item in
            let occurrences = item.nextOccurrences(count: 12, from: Date())
            return occurrences.contains { calendar.isDate($0, inSameDayAs: selectedDate) }
        }
    }
}