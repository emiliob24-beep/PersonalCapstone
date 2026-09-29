//
//  AddScheduledTaskView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/20/26.
//

import SwiftUI
internal import CoreData

struct AddScheduledTaskView: View {

    @ObservedObject var vehicle: Vehicle

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var status: String = "Upcoming"
    @State private var includeDueDate = true
    @State private var dueDate = Date()
    @State private var dueMileage: String = ""
    @State private var estimatedCost: String = ""
    @State private var notes: String = ""
    
    @AppStorage("maintenanceRemindersEnabled") private var maintenanceReminders = true
    @AppStorage("serviceAlertsEnabled") private var serviceAlerts = true 

    private let statusOptions = ["Upcoming", "Due Soon", "Scheduled"]

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
            .navigationTitle("Add Task")
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
        let task = ScheduledTask(context: context)
        task.id = UUID()
        task.title = title
        task.status = status
        task.dueDate = includeDueDate ? dueDate : nil
        task.dueMileage = Int32(dueMileage) ?? 0
        task.estimatedCost = Double(estimatedCost) ?? 0
        task.notes = notes.isEmpty ? nil : notes
        task.vehicle = vehicle

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save scheduled task: \(error)")
        }
    }
}
