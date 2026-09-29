//
//  EditRegistrationView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//


import SwiftUI
internal import CoreData

struct EditRegistrationView: View {

    @ObservedObject var registration: Registration

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("expirationAlertsEnabled") private var expirationAlerts = true

    @State private var state: String
    @State private var plateNumber: String
    @State private var expirationDate: Date

    init(registration: Registration) {
        self.registration = registration
        _state = State(initialValue: registration.state ?? "")
        _plateNumber = State(initialValue: registration.plateNumber ?? "")
        _expirationDate = State(initialValue: registration.expirationDate ?? Date())
    }

    private var isValid: Bool {
        !state.trimmingCharacters(in: .whitespaces).isEmpty
        && !plateNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("State", text: $state)
                    .textInputAutocapitalization(.characters)
                TextField("Plate Number", text: $plateNumber)
                    .textInputAutocapitalization(.characters)
                DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
            }
            .navigationTitle("Edit Registration")
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
        registration.state = state
        registration.plateNumber = plateNumber
        registration.expirationDate = expirationDate

        do {
            try context.save()
            NotificationManager.shared.scheduleExpirationNotification(
                id: registration.id ?? UUID(),
                label: "Registration",
                expirationDate: expirationDate,
                enabled: expirationAlerts
            )
            dismiss()
        } catch {
            print("Failed to update registration: \(error)")
        }
    }
}
