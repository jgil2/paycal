import Foundation
import SwiftData

enum ItemType: String, Codable, CaseIterable, Identifiable {
    case paycheck = "Paycheck"
    case bill = "Bill"
    case subscription = "Subscription"
    
    var id: String { rawValue }
    
    var isIncome: Bool {
        return self == .paycheck
    }
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

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        dueDate: Date,
        type: ItemType,
        repeatInterval: RepeatInterval = .none,
        reminderLeadTime: ReminderLeadTime = .sameDay,
        reminderTime: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.typeRaw = type.rawValue
        self.repeatIntervalRaw = repeatInterval.rawValue
        self.reminderLeadTimeRaw = reminderLeadTime.rawValue
        self.reminderTime = reminderTime
    }

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

    /// Calculates next 'count' occurrences starting from current due date or relative to now
    func nextOccurrences(limit count: Int = 2, relativeTo now: Date = Date()) -> [Date] {
        var occurrences: [Date] = []
        var current = dueDate
        
        // Advance current date if repeat is active and initial date has passed
        while current < Calendar.current.startOfDay(for: now) && repeatInterval != .none {
            guard let next = advanceDate(current, by: repeatInterval) else { break }
            current = next
        }

        for _ in 0..<count {
            occurrences.append(current)
            if repeatInterval == .none { break }
            guard let next = advanceDate(current, by: repeatInterval) else { break }
            current = next
        }

        return occurrences
    }

    /// Calculate the precise trigger Date for a reminder given a specific due date
    func reminderDate(for occurrenceDueDate: Date) -> Date {
        let calendar = Calendar.current
        // Subtract lead time days
        guard let leadDate = calendar.date(byAdding: .day, value: -reminderLeadTime.daysBefore, to: occurrenceDueDate) else {
            return occurrenceDueDate
        }
        
        // Overlay time of day components from reminderTime
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        return calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: leadDate) ?? leadDate
    }

    private func advanceDate(_ date: Date, by interval: RepeatInterval) -> Date? {
        let calendar = Calendar.current
        switch interval {
        case .none: return nil
        case .weekly: return calendar.date(byAdding: .day, value: 7, to: date)
        case .biweekly: return calendar.date(byAdding: .day, value: 14, to: date)
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly: return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}
