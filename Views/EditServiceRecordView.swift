//
//  EditServiceRecordView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/26/26.
//


import SwiftUI
internal import CoreData

struct EditServiceRecordView: View {

    @ObservedObject var record: ServiceRecord

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var mileage: String
    @State private var type: String
    @State private var cost: String
    @State private var shop: String
    @State private var notes: String

    init(record: ServiceRecord) {
        self.record = record
        _date = State(initialValue: record.date ?? Date())
        _mileage = State(initialValue: String(record.mileage))
        _type = State(initialValue: record.type ?? "")
        _cost = State(initialValue: String(record.cost))
        _shop = State(initialValue: record.shop ?? "")
        _notes = State(initialValue: record.notes ?? "")
    }

    private var isValid: Bool {
        !type.trimmingCharacters(in: .whitespaces).isEmpty
        && Int32(mileage) != nil
        && Double(cost) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("Type (e.g. Oil Change)", text: $type)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                    TextField("Cost", text: $cost)
                        .keyboardType(.decimalPad)
                }

                Section("Details") {
                    TextField("Shop (optional)", text: $shop)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Service Record")
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
        record.date = date
        record.mileage = Int32(mileage) ?? 0
        record.type = type
        record.cost = Double(cost) ?? 0
        record.shop = shop.isEmpty ? nil : shop
        record.notes = notes.isEmpty ? nil : notes

        if let vehicle = record.vehicle, record.mileage > vehicle.odometer {
            vehicle.odometer = record.mileage
        }

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to update service record: \(error)")
        }
    }
}
