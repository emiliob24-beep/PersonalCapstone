//
//  AddServiceRecordView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/18/26.
//
//  Manual service record entry, attached to a specific vehicle.
//  Scanning a receipt runs on-device OCR (see ReceiptScanner.swift) to
//  pre-fill cost/date/mileage/shop, which the user can still edit.
//

import SwiftUI
internal import CoreData

struct AddServiceRecordView: View {

    @ObservedObject var vehicle: Vehicle

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var mileage: String = ""
    @State private var type: String = ""
    @State private var cost: String = ""
    @State private var shop: String = ""
    @State private var notes: String = ""

    @State private var showingScanner = false
    @State private var receiptImageData: Data?

    private var isValid: Bool {
        !type.trimmingCharacters(in: .whitespaces).isEmpty
        && Int32(mileage) != nil
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
            .navigationTitle("Add Service Record")
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
                        if let scannedDate = result.date { date = scannedDate }
                        if let scannedMileage = result.mileage { mileage = String(scannedMileage) }
                        if let scannedShop = result.shop { shop = scannedShop }
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
        let record = ServiceRecord(context: context)
        record.id = UUID()
        record.date = date
        record.mileage = Int32(mileage) ?? 0
        record.type = type
        record.cost = Double(cost) ?? 0
        record.shop = shop.isEmpty ? nil : shop
        record.notes = notes.isEmpty ? nil : notes
        record.vehicle = vehicle
        record.receiptPhotoData = receiptImageData

        if record.mileage > vehicle.odometer {
            vehicle.odometer = record.mileage
        }

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save service record: \(error)")
        }
    }
}
