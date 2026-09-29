//
//  AddPartView.swift
//  PersonalCapstone
//
//  Manual part entry, attached to a specific vehicle. Reuses the same
//  receipt-scan OCR flow as AddServiceRecordView to pre-fill cost/date/
//  purchasedFrom from a photo of the receipt.
//

import SwiftUI
internal import CoreData

struct AddPartView: View {

    @ObservedObject var vehicle: Vehicle

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var partNumber: String = ""
    @State private var quantity: String = "1"
    @State private var cost: String = ""
    @State private var datePurchased = Date()
    @State private var purchasedFrom: String = ""
    @State private var notes: String = ""

    @State private var showingScanner = false
    @State private var receiptImageData: Data?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && Int32(quantity) != nil
        && Double(cost) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingScanner = true
                    } label: {
                        Label(
                            receiptImageData == nil ? "Scan Receipt" : "Rescan Receipt",
                            systemImage: "doc.text.viewfinder"
                        )
                    }
                } footer: {
                    if receiptImageData != nil {
                        Text("Receipt scanned — details below were pre-filled and can be edited.")
                    }
                }

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
            .navigationTitle("Add Part")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                ReceiptScanner(
                    onScan: { result in
                        showingScanner = false
                        receiptImageData = result.imageData
                        if let scannedCost = result.cost { cost = String(format: "%.2f", scannedCost) }
                        if let scannedDate = result.date { datePurchased = scannedDate }
                        if let scannedShop = result.shop { purchasedFrom = scannedShop }
                    },
                    onCancel: {
                        showingScanner = false
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    private func save() {
        let part = Part(context: context)
        part.id = UUID()
        part.name = name
        part.partNumber = partNumber.isEmpty ? nil : partNumber
        part.quantity = Int32(quantity) ?? 1
        part.cost = Double(cost) ?? 0
        part.datePurchased = datePurchased
        part.purchasedFrom = purchasedFrom.isEmpty ? nil : purchasedFrom
        part.notes = notes.isEmpty ? nil : notes
        part.vehicle = vehicle
        part.receiptPhotoData = receiptImageData

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save part: \(error)")
        }
    }
}
