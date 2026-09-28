import Foundation
import UserNotifications
import SwiftData

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    struct PendingNotificationCandidate {
        let item: PayCalItem
        let dueDate: Date
        let triggerDate: Date
    }

    /// Rebuilds all scheduled notifications: takes next 2 occurrences per item, sorts, and caps to soonest 64
    func rescheduleAllNotifications(context: ModelContext) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let descriptor = FetchDescriptor<PayCalItem>()
        guard let items = try? context.fetch(descriptor) else { return }

        let now = Date()
        var candidates: [PendingNotificationCandidate] = []

        // Gather candidates for next 2 occurrences per item
        for item in items {
            let occurrences = item.nextOccurrences(limit: 2, relativeTo: now)
            for occDate in occurrences {
                let trigDate = item.reminderDate(for: occDate)
                if trigDate > now {
                    candidates.append(PendingNotificationCandidate(item: item, dueDate: occDate, triggerDate: trigDate))
                }
            }
        }

        // Sort by trigger date ascending and enforce iOS maximum 64 limit
        candidates.sort { $0.triggerDate < $1.triggerDate }
        let scheduledCandidates = Array(candidates.prefix(64))

        for candidate in scheduledCandidates {
            scheduleNotification(for: candidate)
        }
    }

    private func scheduleNotification(for candidate: PendingNotificationCandidate) {
        let content = UNMutableNotificationContent()
        let formattedAmount = String(format: "$%.2f", candidate.item.amount)
        
        content.title = "\(candidate.item.type.rawValue): \(candidate.item.name)"
        content.body = "Amount: \(formattedAmount) is due on \(candidate.dueDate.formatted(date: .abbreviated, time: .omitted))."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: candidate.triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let requestID = "\(candidate.item.id.uuidString)-\(candidate.dueDate.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
