//
//  AddInsuranceView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//


import SwiftUI
internal import CoreData

struct AddInsuranceView: View {

    @ObservedObject var vehicle: Vehicle

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var provider: String = ""
    @State private var policyNumber: String = ""
    @State private var expirationDate = Date()
    
    @AppStorage("expirationAlertsEnabled") private var expirationAlerts = true 

    private var isValid: Bool {
        !provider.trimmingCharacters(in: .whitespaces).isEmpty
        && !policyNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Provider", text: $provider)
                TextField("Policy Number", text: $policyNumber)
                DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
            }
            .navigationTitle("Add Insurance")
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
        let insurance = Insurance(context: context)
        insurance.id = UUID()
        insurance.provider = provider
        insurance.policyNumber = policyNumber
        insurance.expirationDate = expirationDate
        insurance.vehicle = vehicle

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save insurance: \(error)")
        }
    }
}
