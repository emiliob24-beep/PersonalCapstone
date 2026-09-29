//
//  EditScheduledTaskView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/1/26.
//


import SwiftUI
internal import CoreData

struct EditScheduledTaskView: View {

    @ObservedObject var task: ScheduledTask

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("maintenanceRemindersEnabled") private var maintenanceReminders = true
    @AppStorage("serviceAlertsEnabled") private var serviceAlerts = true

    @State private var title: String
    @State private var status: String
    @State private var includeDueDate: Bool
    @State private var dueDate: Date
    @State private var dueMileage: String
    @State private var estimatedCost: String
    @State private var notes: String

    private let statusOptions = ["Upcoming", "Due Soon", "Scheduled"]

    init(task: ScheduledTask) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _status = State(initialValue: task.status ?? "Upcoming")
        _includeDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _dueMileage = State(initialValue: task.dueMileage > 0 ? String(task.dueMileage) : "")
        _estimatedCost = State(initialValue: task.estimatedCost > 0 ? String(task.estimatedCost) : "")
        _notes = State(initialValue: task.notes ?? "")
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title (e.g. Brake Fluid Flush)", text: $title)
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { Text(LocalizedStringKey($0)) }
                    }
                }

                Section("Due") {
                    Toggle("Has due date", isOn: $includeDueDate)
                    if includeDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                    TextField("Due Mileage (optional)", text: $dueMileage)
                        .keyboardType(.numberPad)
                }

                Section("Details") {
                    TextField("Estimated Cost (optional)", text: $estimatedCost)
                        .keyboardType(.decimalPad)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        task.title = title
        task.status = status
        task.dueDate = includeDueDate ? dueDate : nil
        task.dueMileage = Int32(dueMileage) ?? 0
        task.estimatedCost = Double(estimatedCost) ?? 0
        task.notes = notes.isEmpty ? nil : notes

        do {
            try context.save()
            // Reschedule: cancels old notifications and schedules fresh ones
            // based on the (possibly changed) due date and current toggle state.
            NotificationManager.shared.scheduleTaskNotifications(
                taskID: task.id ?? UUID(),
                title: title,
                dueDate: task.dueDate,
                maintenanceRemindersEnabled: maintenanceReminders,
                serviceAlertsEnabled: serviceAlerts
            )
            dismiss()
        } catch {
            print("Failed to update scheduled task: \(error)")
        }
    }
}
