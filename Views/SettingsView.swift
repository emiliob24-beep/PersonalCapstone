//
//  SettingsView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//
//  The Settings tab: vehicle details, insurance/registration (one each,
//  since those are to-one relationships), documents, and notification
//  toggles for whichever vehicle is selected in Garage.
//
//  Documents in this pass are metadata-only (title/category/date) —
//  actual file attachment (fileData) is a polish-phase addition.
//

import SwiftUI
import CloudKit
internal import CoreData

struct SettingsView: View {

    @EnvironmentObject private var appState: AppState
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.createdDate, ascending: true)],
        animation: .default
    )
    private var vehicles: FetchedResults<Vehicle>

    // Notification prefs are app-wide (not per-vehicle), so @AppStorage is fine here.
    @AppStorage("maintenanceRemindersEnabled") private var maintenanceReminders = true
    @AppStorage("serviceAlertsEnabled") private var serviceAlerts = true
    @AppStorage("expirationAlertsEnabled") private var expirationAlerts = true
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    @State private var showingAddInsurance = false
    @State private var showingAddRegistration = false
    @State private var showingAddDocument = false
    @State private var documentToPreview: Document?
    @State private var showingEditVehicle = false
    @State private var showingEditInsurance = false
    @State private var showingEditRegistration = false
    @State private var showingDeleteConfirmation = false

    @State private var isPreparingShare = false
    @State private var shareError: String?
    @State private var activeShare: CKShare?
    @State private var activeCKContainer: CKContainer?
    @State private var showingShareSheet = false

    private var selectedVehicle: Vehicle? {
        guard let id = appState.selectedVehicleID else { return nil }
        return vehicles.first { $0.objectID == id }
    }

    private var documents: [Document] {
        guard let vehicle = selectedVehicle else { return [] }
        let set = vehicle.documents as? Set<Document> ?? []
        return set.sorted { ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vehicle = selectedVehicle {
                    List {
                        vehicleSection(vehicle)
                        // Family sharing UI is temporarily hidden for the App
                        // Store submission — see the CKShare investigation.
                        // Re-add this branch once that's fixed:
                        // if vehicle.isSharedWithMe {
                        //     sharedWithMeNoticeSection
                        // } else {
                        //     familySharingSection(vehicle)
                        // }
                        partsSection(vehicle)
                        insuranceSection(vehicle)
                        registrationSection(vehicle)
                        documentsSection(vehicle)
                        languageSection
                        notificationsSection
                        if !vehicle.isSharedWithMe {
                            dangerZoneSection(vehicle)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Vehicle Selected",
                        systemImage: "car.fill",
                        description: Text("Add a vehicle in the Garage tab first.")
                    )
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddInsurance) {
                if let vehicle = selectedVehicle {
                    AddInsuranceView(vehicle: vehicle)
                }
            }
            .sheet(isPresented: $showingAddRegistration) {
                if let vehicle = selectedVehicle {
                    AddRegistrationView(vehicle: vehicle)
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                if let vehicle = selectedVehicle {
                    AddDocumentView(vehicle: vehicle)
                }
            }
            .sheet(item: $documentToPreview) { document in
                DocumentPreviewView(document: document)
            }
            .sheet(isPresented: $showingEditVehicle) {
                if let vehicle = selectedVehicle {
                    EditVehicleView(vehicle: vehicle)
                }
            }
            .sheet(isPresented: $showingEditInsurance) {
                if let insurance = selectedVehicle?.insurance {
                    EditInsuranceView(insurance: insurance)
                }
            }
            .sheet(isPresented: $showingEditRegistration) {
                if let registration = selectedVehicle?.registration {
                    EditRegistrationView(registration: registration)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let activeShare, let activeCKContainer, let vehicle = selectedVehicle {
                    CloudSharingView(
                        share: activeShare,
                        container: activeCKContainer,
                        itemTitle: "\(String(vehicle.year)) \(vehicle.make ?? "") \(vehicle.model ?? "")"
                    )
                }
            }
        }
    }

    // MARK: - Vehicle

    private func vehicleSection(_ vehicle: Vehicle) -> some View {
        Section("Vehicle") {
            Button {
                showingEditVehicle = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(String(vehicle.year)) \(vehicle.make ?? "") \(vehicle.model ?? "")")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    if let trim = vehicle.trim, !trim.isEmpty {
                        Text(trim)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let color = vehicle.color, !color.isEmpty {
                        Text(color)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let vin = vehicle.vin, !vin.isEmpty {
                        (Text("VIN:") + Text(verbatim: " \(vin)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let plate = vehicle.licensePlate, !plate.isEmpty {
                        (Text("Plate:") + Text(verbatim: " \(plate)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Family Sharing

    private var sharedWithMeNoticeSection: some View {
        Section {
            Label("Shared with you by a family member", systemImage: "person.2.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func familySharingSection(_ vehicle: Vehicle) -> some View {
        Section {
            Button {
                presentSharingController(for: vehicle)
            } label: {
                if isPreparingShare {
                    HStack {
                        ProgressView()
                        Text("Preparing...")
                    }
                } else {
                    Label("Share This Vehicle", systemImage: "person.2.badge.plus")
                }
            }
            .disabled(isPreparingShare)

            if let shareError {
                Text(shareError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Family Sharing")
        } footer: {
            Text("Invite a family member to view and edit this car's records. Tap again anytime to manage who has access.")
        }
    }

    private func presentSharingController(for vehicle: Vehicle) {
        shareError = nil
        isPreparingShare = true

        let persistentContainer = PersistenceController.shared.container

        // Reuse an existing share if this vehicle was already shared before —
        // avoids creating a second, orphaned share on repeated taps, and opens
        // the management view (add/remove people) instead.
        if let existingShares = try? persistentContainer.fetchShares(matching: [vehicle.objectID]),
           let existingShare = existingShares[vehicle.objectID] {
            activeShare = existingShare
            activeCKContainer = CKContainer(identifier: "iCloud.com.emiliobriceno.PersonalCapstone")
            isPreparingShare = false
            showingShareSheet = true
            return
        }

        // NOTE: this completion handler takes FOUR parameters — objectIDs
        // (per-object errors, if any), share, container, error — not three.
        persistentContainer.share([vehicle], to: nil) { objectIDs, share, ckContainer, error in
            DispatchQueue.main.async {
                isPreparingShare = false
                if let error {
                    shareError = error.localizedDescription
                    return
                }
                guard let share, let ckContainer else {
                    shareError = "Could not create a share for this vehicle."
                    return
                }
                activeShare = share
                activeCKContainer = ckContainer
                showingShareSheet = true
            }
        }
    }

    // MARK: - Parts

    private func partsSection(_ vehicle: Vehicle) -> some View {
        Section {
            NavigationLink {
                PartsListView(vehicle: vehicle)
            } label: {
                Label("Parts", systemImage: "shippingbox")
            }
        }
    }

    // MARK: - Insurance

    private func insuranceSection(_ vehicle: Vehicle) -> some View {
        Section("Insurance") {
            if let insurance = vehicle.insurance {
                Button {
                    showingEditInsurance = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(LocalizedStringKey(insurance.provider ?? "Unknown provider"))
                                .font(.subheadline.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        (Text("Policy:") + Text(verbatim: " \(insurance.policyNumber ?? "—")"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let expiration = insurance.expirationDate {
                            (Text("Expires") + Text(verbatim: " \(expiration.formatted(date: .abbreviated, time: .omitted))"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            } else {
                Button {
                    showingAddInsurance = true
                } label: {
                    Label("Add Insurance", systemImage: "plus.circle")
                }
            }
        }
    }

    // MARK: - Registration

    private func registrationSection(_ vehicle: Vehicle) -> some View {
        Section("Registration") {
            if let registration = vehicle.registration {
                Button {
                    showingEditRegistration = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(registration.state ?? "—") · \(registration.plateNumber ?? "—")")
                                .font(.subheadline.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        if let expiration = registration.expirationDate {
                            (Text("Expires") + Text(verbatim: " \(expiration.formatted(date: .abbreviated, time: .omitted))"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            } else {
                Button {
                    showingAddRegistration = true
                } label: {
                    Label("Add Registration", systemImage: "plus.circle")
                }
            }
        }
    }

    // MARK: - Documents

    private func documentsSection(_ vehicle: Vehicle) -> some View {
        Section("Documents") {
            if documents.isEmpty {
                Text("No documents yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(documents) { document in
                    Button {
                        documentToPreview = document
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(Color.appAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(document.title ?? "Untitled"))
                                    .font(.subheadline)
                                if let category = document.category, !category.isEmpty {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(documents[index]) }
                    try? context.save()
                }
            }
            Button {
                showingAddDocument = true
            } label: {
                Label("Add Document", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        Section {
            Picker("Language", selection: $appLanguage) {
                Text("System").tag("system")
                Text(verbatim: "English").tag("en")
                Text(verbatim: "Español").tag("es")
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Maintenance Reminders", isOn: $maintenanceReminders)
            Toggle("Service Alerts", isOn: $serviceAlerts)
            Toggle("Insurance/Registration Expiring", isOn: $expirationAlerts)

//            // TODO (remove before final submission): quick way to verify
//            // notification permission + delivery without waiting days.
//            Button("Send Test Notification (fires in 10s)") {
//                NotificationManager.shared.sendTestNotification()
//            }
        }
    }

    // MARK: - Danger Zone

    private func dangerZoneSection(_ vehicle: Vehicle) -> some View {
        Section {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Text("Delete Vehicle")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .confirmationDialog(
                "Delete \(String(vehicle.year)) \(vehicle.make ?? "") \(vehicle.model ?? "")?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Vehicle", role: .destructive) {
                    deleteVehicle(vehicle)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes this vehicle and all its service records, scheduled tasks, insurance, registration, and documents. This can't be undone.")
            }
        } footer: {
            Text("Permanently removes this vehicle and everything attached to it.")
        }
    }

    private func deleteVehicle(_ vehicle: Vehicle) {
        // Cancel notifications tied to this vehicle's records before Core Data
        // cascade-deletes the records themselves — notifications live outside
        // Core Data and won't clean up on their own.
        for task in vehicle.scheduledTasks as? Set<ScheduledTask> ?? [] {
            if let id = task.id {
                NotificationManager.shared.cancelTaskNotifications(taskID: id)
            }
        }
        if let insuranceID = vehicle.insurance?.id {
            NotificationManager.shared.cancelExpirationNotification(id: insuranceID)
        }
        if let registrationID = vehicle.registration?.id {
            NotificationManager.shared.cancelExpirationNotification(id: registrationID)
        }

        context.delete(vehicle)
        try? context.save()
        appState.selectedTab = .garage
    }
}

