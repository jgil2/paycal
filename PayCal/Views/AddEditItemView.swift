import SwiftUI
import SwiftData

struct AddEditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var itemToEdit: PayCalItem?
    
    @State private var name: String = ""
    @State private var amountString: String = ""
    @State private var dueDate: Date = Date()
    @State private var type: ItemType = .bill
    @State private var repeatInterval: RepeatInterval = .none
    @State private var reminderLeadTime: ReminderLeadTime = .sameDay
    @State private var reminderTime: Date = Date()
    @State private var isPaid: Bool = false
    @State private var iconName: String = "dollarsign.circle.fill"
    @State private var customEmojiInput: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Item Name", text: $name)
                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                    Picker("Type", selection: $type) {
                        ForEach(ItemType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Toggle("Mark as Paid", isOn: $isPaid)
                }
                
                Section("Icon & Emoji") {
                    // Custom emoji keyboard input field
                    HStack {
                        Text("Custom Emoji:")
                        Spacer()
                        TextField("Type emoji...", text: $customEmojiInput)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                            .onChange(of: customEmojiInput) { _, newValue in
                                if let lastChar = newValue.last, lastChar.isEmoji {
                                    iconName = String(lastChar)
                                }
                            }
                        ItemIconView(iconName: iconName, itemType: type)
                    }
                    
                    // Quick Emoji Picker Grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preset Emojis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(PayCalItem.availableEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(iconName == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(iconName == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        iconName = emoji
                                        customEmojiInput = emoji
                                    }
                            }
                        }
                    }
                    
                    // SF Symbols Grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Icons")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(PayCalItem.availableIcons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(iconName == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(iconName == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        iconName = icon
                                        customEmojiInput = ""
                                    }
                            }
                        }
                    }
                }
                
                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    Picker("Repeat", selection: $repeatInterval) {
                        ForEach(RepeatInterval.allCases) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                }
                
                Section("Reminders") {
                    Picker("Lead Time", selection: $reminderLeadTime) {
                        ForEach(ReminderLeadTime.allCases) { lead in
                            Text(lead.rawValue).tag(lead)
                        }
                    }
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle(itemToEdit == nil ? "New Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(name.isEmpty || Double(amountString) == nil)
                }
            }
            .onAppear {
                if let item = itemToEdit {
                    name = item.name
                    amountString = String(item.amount)
                    dueDate = item.dueDate
                    type = item.type
                    repeatInterval = item.repeatInterval
                    reminderLeadTime = item.reminderLeadTime
                    reminderTime = item.reminderTime
                    isPaid = item.isPaid
                    iconName = item.iconName
                    if item.isEmoji {
                        customEmojiInput = item.iconName
                    }
                }
            }
        }
    }
    
    private func saveItem() {
        let amount = Double(amountString) ?? 0.0
        
        if let item = itemToEdit {
            item.name = name
            item.amount = amount
            item.dueDate = dueDate
            item.type = type
            item.repeatInterval = repeatInterval
            item.reminderLeadTime = reminderLeadTime
            item.reminderTime = reminderTime
            item.isPaid = isPaid
            item.iconName = iconName
        } else {
            let newItem = PayCalItem(
                name: name,
                amount: amount,
                dueDate: dueDate,
                type: type,
                repeatInterval: repeatInterval,
                reminderLeadTime: reminderLeadTime,
                reminderTime: reminderTime,
                isPaid: isPaid,
                iconName: iconName
            )
            modelContext.insert(newItem)
        }
        
        Task {
            let fetchDescriptor = FetchDescriptor<PayCalItem>()
            if let allItems = try? modelContext.fetch(fetchDescriptor) {
                await NotificationManager.shared.scheduleNotifications(for: allItems)
            }
        }
    }
}