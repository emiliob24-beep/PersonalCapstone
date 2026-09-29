//
//  EditInsuranceView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//


import SwiftUI
internal import CoreData

struct EditInsuranceView: View {

    @ObservedObject var insurance: Insurance

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("expirationAlertsEnabled") private var expirationAlerts = true

    @State private var provider: String
    @State private var policyNumber: String
    @State private var expirationDate: Date

    init(insurance: Insurance) {
        self.insurance = insurance
        _provider = State(initialValue: insurance.provider ?? "")
        _policyNumber = State(initialValue: insurance.policyNumber ?? "")
        _expirationDate = State(initialValue: insurance.expirationDate ?? Date())
    }

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
            .navigationTitle("Edit Insurance")
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
        insurance.provider = provider
        insurance.policyNumber = policyNumber
        insurance.expirationDate = expirationDate

        do {
            try context.save()
            NotificationManager.shared.scheduleExpirationNotification(
                id: insurance.id ?? UUID(),
                label: "Insurance",
                expirationDate: expirationDate,
                enabled: expirationAlerts
            )
            dismiss()
        } catch {
            print("Failed to update insurance: \(error)")
        }
    }
}
