//
//  NotificationManager.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//
//
import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    //Scheduled Task notifications
    func scheduleTaskNotifications(
        taskID: UUID,
        title: String,
        dueDate: Date?,
        maintenanceRemindersEnabled: Bool,
        serviceAlertsEnabled: Bool
    ) {
        cancelTaskNotifications(taskID: taskID)

        guard let dueDate else { return }
        let now = Date()

        if maintenanceRemindersEnabled,
           let headsUpDate = Calendar.current.date(byAdding: .day, value: -7, to: dueDate),
           headsUpDate > now {
            schedule(
                identifier: "task-reminder-\(taskID.uuidString)",
                title: "Upcoming Maintenance",
                body: "\(title) is due in about a week.",
                date: headsUpDate
            )
        }

        if serviceAlertsEnabled {
            var dueDayComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            dueDayComponents.hour = 9 // 9AM on the due date
            if let dueDayDate = Calendar.current.date(from: dueDayComponents), dueDayDate > now {
                schedule(
                    identifier: "task-duesoon-\(taskID.uuidString)",
                    title: "Service Due Today",
                    body: "\(title) is due today.",
                    date: dueDayDate
                )
            }
        }
    }

    func cancelTaskNotifications(taskID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "task-reminder-\(taskID.uuidString)",
            "task-duesoon-\(taskID.uuidString)"
        ])
    }

    //Expiration notifications (Insurance / Registration)

    func scheduleExpirationNotification(id: UUID, label: String, expirationDate: Date, enabled: Bool) {
        cancelExpirationNotification(id: id)
        guard enabled else { return }

        guard let alertDate = Calendar.current.date(byAdding: .day, value: -30, to: expirationDate),
              alertDate > Date() else { return }

        schedule(
            identifier: "expiration-\(id.uuidString)",
            title: "\(label) Expiring Soon",
            body: "Your \(label.lowercased()) expires on \(expirationDate.formatted(date: .abbreviated, time: .omitted)).",
            date: alertDate
        )
    }

    func cancelExpirationNotification(id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["expiration-\(id.uuidString)"])
    }
    
    //Core scheduling helper
    private func schedule(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                print("Failed to schedule notification \(identifier): \(error)")
            }
        }
    }
}
