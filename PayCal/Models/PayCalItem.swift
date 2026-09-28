import Foundation
import SwiftData

enum ItemType: String, Codable, CaseIterable, Identifiable {
    case paycheck = "Paycheck"
    case bill = "Bill"
    case subscription = "Subscription"
    
    var id: String { rawValue }
}

enum RepeatInterval: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { rawValue }
}

enum ReminderLeadTime: String, Codable, CaseIterable, Identifiable {
    case sameDay = "Same day"
    case oneDay = "1 day before"
    case threeDays = "3 days before"
    case oneWeek = "1 week before"
    
    var id: String { rawValue }
    
    var daysBefore: Int {
        switch self {
        case .sameDay: return 0
        case .oneDay: return 1
        case .threeDays: return 3
        case .oneWeek: return 7
        }
    }
}

@Model
final class PayCalItem {
    var id: UUID
    var name: String
    var amount: Double
    var dueDate: Date
    var typeRaw: String
    var repeatIntervalRaw: String
    var reminderLeadTimeRaw: String
    var reminderTime: Date
    var isPaid: Bool = false
    var iconName: String = "dollarsign.circle.fill"
    
    var type: ItemType {
        get { ItemType(rawValue: typeRaw) ?? .bill }
        set { typeRaw = newValue.rawValue }
    }
    
    var repeatInterval: RepeatInterval {
        get { RepeatInterval(rawValue: repeatIntervalRaw) ?? .none }
        set { repeatIntervalRaw = newValue.rawValue }
    }
    
    var reminderLeadTime: ReminderLeadTime {
        get { ReminderLeadTime(rawValue: reminderLeadTimeRaw) ?? .sameDay }
        set { reminderLeadTimeRaw = newValue.rawValue }
    }
    
    // Helper to determine if iconName is an emoji vs SF Symbol
    var isEmoji: Bool {
        guard let first = iconName.first else { return false }
        return first.isEmoji && !first.isASCII
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        dueDate: Date,
        type: ItemType,
        repeatInterval: RepeatInterval,
        reminderLeadTime: ReminderLeadTime,
        reminderTime: Date,
        isPaid: Bool = false,
        iconName: String = "dollarsign.circle.fill"
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.typeRaw = type.rawValue
        self.repeatIntervalRaw = repeatInterval.rawValue
        self.reminderLeadTimeRaw = reminderLeadTime.rawValue
        self.reminderTime = reminderTime
        self.isPaid = isPaid
        self.iconName = iconName
    }
    
    // SF Symbols preset list
    static let availableIcons = [
        "dollarsign.circle.fill",
        "creditcard.fill",
        "cart.fill",
        "house.fill",
        "car.fill",
        "bolt.fill",
        "wifi",
        "phone.fill",
        "tv.fill",
        "cross.case.fill",
        "graduationcap.fill",
        "gift.fill",
        "bag.fill",
        "doc.text.fill"
    ]
    
    // Quick-select preset emojis
    static let availableEmojis = [
        "💰", "💸", "💳", "💵", "🏠", "⚡️", "📱", "🚗", "🛒", "🍔",
        "🍿", "🏥", "🎓", "✈️", "🏋️‍♂️", "🎮", "🐾", "🎁", "💧", "🛡️"
    ]
    
    func nextDueDate(after date: Date = Date()) -> Date? {
        var current = dueDate
        if current >= Calendar.current.startOfDay(for: date) {
            return current
        }
        guard repeatInterval != .none else { return nil }
        
        let calendar = Calendar.current
        while current < calendar.startOfDay(for: date) {
            switch repeatInterval {
            case .none:
                return nil
            case .weekly:
                guard let next = calendar.date(byAdding: .day, value: 7, to: current) else { return nil }
                current = next
            case .biweekly:
                guard let next = calendar.date(byAdding: .day, value: 14, to: current) else { return nil }
                current = next
            case .monthly:
                guard let next = calendar.date(byAdding: .month, value: 1, to: current) else { return nil }
                current = next
            case .yearly:
                guard let next = calendar.date(byAdding: .year, value: 1, to: current) else { return nil }
                current = next
            }
        }
        return current
    }
    
    func nextOccurrences(count: Int, from date: Date = Date()) -> [Date] {
        var results: [Date] = []
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        
        var current: Date? = dueDate
        while let dateToCheck = current, results.count < count {
            if dateToCheck >= startOfToday {
                results.append(dateToCheck)
            }
            if repeatInterval == .none { break }
            
            switch repeatInterval {
            case .none:
                current = nil
            case .weekly:
                current = calendar.date(byAdding: .day, value: 7, to: dateToCheck)
            case .biweekly:
                current = calendar.date(byAdding: .day, value: 14, to: dateToCheck)
            case .monthly:
                current = calendar.date(byAdding: .month, value: 1, to: dateToCheck)
            case .yearly:
                current = calendar.date(byAdding: .year, value: 1, to: dateToCheck)
            }
        }
        return results
    }
}