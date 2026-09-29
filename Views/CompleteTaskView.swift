//
//  CompleteTaskView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/25/26.
//


import SwiftUI
internal import CoreData

struct CompleteTaskView: View {

    @ObservedObject var task: ScheduledTask

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var mileage: String
    @State private var cost: String
    @State private var shop: String = ""
    @State private var notes: String

    init(task: ScheduledTask) {
        self.task = task
        _date = State(initialValue: Date())
        _mileage = State(initialValue: task.dueMileage > 0 ? String(task.dueMileage) : "")
        _cost = State(initialValue: task.estimatedCost > 0 ? String(task.estimatedCost) : "")
        _notes = State(initialValue: task.notes ?? "")
    }

    private var isValid: Bool {
        Int32(mileage) != nil && Double(cost) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    (Text("Completing:") + Text(verbatim: " \(task.title ?? "Task")"))
                        .font(.subheadline.bold())
                }

                Section("Actual Service Details") {
                    DatePicker("Date Completed", selection: $date, displayedComponents: .date)
                    TextField("Actual Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                    TextField("Actual Cost", text: $cost)
                        .keyboardType(.decimalPad)
                    TextField("Shop (optional)", text: $shop)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Complete Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { complete() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func complete() {
        guard let vehicle = task.vehicle else { return }

        let record = ServiceRecord(context: context)
        record.id = UUID()
        record.date = date
        record.mileage = Int32(mileage) ?? 0
        record.type = task.title ?? "Service"
        record.cost = Double(cost) ?? 0
        record.shop = shop.isEmpty ? nil : shop
        record.notes = notes.isEmpty ? nil : notes
        record.vehicle = vehicle

        if let taskID = task.id {
            NotificationManager.shared.cancelTaskNotifications(taskID: taskID)
        }
        context.delete(task)

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to complete task: \(error)")
        }
    }
}
