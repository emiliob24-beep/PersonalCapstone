//
//  EditPartView.swift
//  PersonalCapstone
//

import SwiftUI
internal import CoreData

struct EditPartView: View {

    @ObservedObject var part: Part

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var partNumber: String
    @State private var quantity: String
    @State private var cost: String
    @State private var datePurchased: Date
    @State private var purchasedFrom: String
    @State private var notes: String

    init(part: Part) {
        self.part = part
        _name = State(initialValue: part.name ?? "")
        _partNumber = State(initialValue: part.partNumber ?? "")
        _quantity = State(initialValue: String(part.quantity))
        _cost = State(initialValue: String(part.cost))
        _datePurchased = State(initialValue: part.datePurchased ?? Date())
        _purchasedFrom = State(initialValue: part.purchasedFrom ?? "")
        _notes = State(initialValue: part.notes ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && Int32(quantity) != nil
        && Double(cost) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Part") {
                    TextField("Name (e.g. Brake Pads)", text: $name)
                    TextField("Part Number (optional)", text: $partNumber)
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                    TextField("Cost", text: $cost)
                        .keyboardType(.decimalPad)
                    DatePicker("Date Purchased", selection: $datePurchased, displayedComponents: .date)
                }

                Section("Details") {
                    TextField("Purchased From (optional)", text: $purchasedFrom)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Part")
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
        part.name = name
        part.partNumber = partNumber.isEmpty ? nil : partNumber
        part.quantity = Int32(quantity) ?? 1
        part.cost = Double(cost) ?? 0
        part.datePurchased = datePurchased
        part.purchasedFrom = purchasedFrom.isEmpty ? nil : purchasedFrom
        part.notes = notes.isEmpty ? nil : notes

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to update part: \(error)")
        }
    }
}
