//
//  AddRegistrationView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//


import SwiftUI
internal import CoreData

struct AddRegistrationView: View {

    @ObservedObject var vehicle: Vehicle

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var state: String = ""
    @State private var plateNumber: String = ""
    @State private var expirationDate = Date()
    
    @AppStorage("expirationAlertsEnabled") private var expirationAlerts = true 

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
            .navigationTitle("Add Registration")
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
        let registration = Registration(context: context)
        registration.id = UUID()
        registration.state = state
        registration.plateNumber = plateNumber
        registration.expirationDate = expirationDate
        registration.vehicle = vehicle

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save registration: \(error)")
        }
    }
}
