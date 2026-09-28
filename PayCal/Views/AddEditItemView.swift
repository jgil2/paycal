import SwiftUI
import SwiftData

struct AddEditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var itemToEdit: PayCalItem?

    @State private var name: String = ""
    @State private var amount: Double = 0.0
    @State private var dueDate: Date = Date()
    @State private var type: ItemType = .bill
    @State private var repeatInterval: RepeatInterval = .none
    @State private var reminderLeadTime: ReminderLeadTime = .sameDay
    @State private var reminderTime: Date = Date()

    var isEditing: Bool { itemToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name (e.g. Electric Bill)", text: $name)
                    
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .keyboardType(.decimalPad)

                    Picker("Type", selection: $type) {
                        ForEach(ItemType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)

                    Picker("Repeat", selection: $repeatInterval) {
                        ForEach(RepeatInterval.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                }

                Section("Reminders") {
                    Picker("Reminder Lead Time", selection: $reminderLeadTime) {
                        ForEach(ReminderLeadTime.allCases) { lead in
                            Text(lead.rawValue).tag(lead)
                        }
                    }

                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let item = itemToEdit {
                    name = item.name
                    amount = item.amount
                    dueDate = item.dueDate
                    type = item.type
                    repeatInterval = item.repeatInterval
                    reminderLeadTime = item.reminderLeadTime
                    reminderTime = item.reminderTime
                }
            }
        }
    }

    private func saveItem() {
        if let item = itemToEdit {
            item.name = name
            item.amount = amount
            item.dueDate = dueDate
            item.type = type
            item.repeatInterval = repeatInterval
            item.reminderLeadTime = reminderLeadTime
            item.reminderTime = reminderTime
        } else {
            let newItem = PayCalItem(
                name: name,
                amount: amount,
                dueDate: dueDate,
                type: type,
                repeatInterval: repeatInterval,
                reminderLeadTime: reminderLeadTime,
                reminderTime: reminderTime
            )
            modelContext.insert(newItem)
        }

        try? modelContext.save()
        // Rebuild 64-capped notification queue after edit
        NotificationManager.shared.rescheduleAllNotifications(context: modelContext)
    }
}
