import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func scheduleNotifications(for items: [PayCalItem]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        var allPending: [(date: Date, item: PayCalItem)] = []
        let now = Date()
        
        for item in items {
            let upcomingDates = item.nextOccurrences(count: 2, from: now)
            for date in upcomingDates {
                let calendar = Calendar.current
                let baseDate = calendar.date(byAdding: .day, value: -item.reminderLeadTime.daysBefore, to: date) ?? date
                let timeComponents = calendar.dateComponents([.hour, .minute], from: item.reminderTime)
                if let remDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: baseDate), remDate > now {
                    allPending.append((remDate, item))
                }
            }
        }
        
        // Capped at iOS 64 notification limit
        let sorted = allPending.sorted { $0.date < $1.date }.prefix(64)
        
        for entry in sorted {
            let content = UNMutableNotificationContent()
            content.title = entry.item.name
            content.body = "Amount: $\(String(format: "%.2f", entry.item.amount)) is due."
            content.sound = .default
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: entry.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            try? await center.add(request)
        }
    }
}