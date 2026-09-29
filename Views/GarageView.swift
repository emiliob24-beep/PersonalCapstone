//
//  GarageView.swift
//  PersonalCapstone
//
//

import SwiftUI
internal import CoreData

struct GarageView: View {

    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var appState: AppState

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.createdDate, ascending: true)],
        animation: .default
    )
    private var vehicles: FetchedResults<Vehicle>

    private var ownedVehicles: [Vehicle] {
        vehicles.filter { !$0.isSharedWithMe }
    }

    @State private var showingAddVehicle = false

    var body: some View {
        NavigationStack {
            Group {
                if ownedVehicles.isEmpty {
                    emptyState
                } else {
                    TabView(selection: $appState.selectedVehicleID) {
                        ForEach(ownedVehicles) { vehicle in
                            VehicleDashboardView(vehicle: vehicle)
                                .tag(vehicle.objectID as NSManagedObjectID?)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                }
            }
            .navigationTitle("Garage")
            .toolbar {
                if ownedVehicles.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        vehicleMenu
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .onAppear { selectFirstVehicleIfNeeded() }
            .onChange(of: ownedVehicles.count) { _, _ in selectFirstVehicleIfNeeded() }
        }
    }

    /// Keeps AppState pointed at a real owned vehicle: picks the first one if
    /// nothing is selected yet, or if the previously selected vehicle
    /// was deleted. Deliberately scoped to owned vehicles only — Family
    /// Garage selections are made explicitly by tapping there instead.
    private func selectFirstVehicleIfNeeded() {
        let stillValid = appState.selectedVehicleID.map { id in ownedVehicles.contains { $0.objectID == id } } ?? false
        if !stillValid {
            appState.selectedVehicleID = ownedVehicles.first?.objectID
        }
    }

    private var selectedVehicle: Vehicle? {
        guard let id = appState.selectedVehicleID else { return nil }
        return ownedVehicles.first { $0.objectID == id }
    }

    private var vehicleMenu: some View {
        Menu {
            ForEach(ownedVehicles) { vehicle in
                Button {
                    appState.selectedVehicleID = vehicle.objectID
                } label: {
                    if vehicle.objectID == appState.selectedVehicleID {
                        Label(vehicleLabel(for: vehicle), systemImage: "checkmark")
                    } else {
                        Text(vehicleLabel(for: vehicle))
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedVehicle.map { vehicleLabel(for: $0) } ?? "Vehicles")
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
    }

    private func vehicleLabel(for vehicle: Vehicle) -> String {
        "\(String(vehicle.year)) \(vehicle.model ?? "")"
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No vehicles yet")
                .font(.title2.bold())
            Text("Add your first car to start tracking maintenance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Vehicle") {
                showingAddVehicle = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Per-vehicle dashboard page

private struct VehicleDashboardView: View {

    @ObservedObject var vehicle: Vehicle

    private var upcomingTasks: [ScheduledTask] {
        let set = vehicle.scheduledTasks as? Set<ScheduledTask> ?? []
        return set.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                vehicleCard
                statsRow
                upcomingSection
            }
            .padding()
        }
    }

    private var vehicleCard: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let plate = vehicle.licensePlate, !plate.isEmpty {
                        Text(verbatim: "\(vehicle.make ?? "") · \(plate)")
                    } else {
                        Text(verbatim: "\(vehicle.make ?? "") · ") + Text("No plate")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text("\(String(vehicle.year)) \(vehicle.model ?? "")")
                    .font(.title.bold())

                HStack(spacing: 6) {
                    if let trim = vehicle.trim, !trim.isEmpty {
                        Text(trim)
                    }
                    if let color = vehicle.color, !color.isEmpty {
                        if vehicle.trim?.isEmpty == false { Text("·") }
                        Text(color)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Label {
                    Text(verbatim: "\(vehicle.odometer) ") + Text("mi")
                } icon: {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                }
                .font(.subheadline)
            }

            Spacer(minLength: 12)

            vehiclePhoto
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var vehiclePhoto: some View {
        Group {
            if let photoData = vehicle.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.secondary.opacity(0.15)
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 104, height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Tasks Pending", value: "\(upcomingTasks.count)")
            statCard(title: "Services Done", value: "\((vehicle.serviceRecords as? Set<ServiceRecord>)?.count ?? 0)")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming")
                .font(.headline)

            if upcomingTasks.isEmpty {
                Text("No upcoming tasks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(upcomingTasks.prefix(4)) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(task.title ?? "Untitled task"))
                                .font(.subheadline.bold())
                            if let dueDate = task.dueDate {
                                Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(LocalizedStringKey(task.status ?? "Upcoming"))
                            .font(.caption.bold())
                            .foregroundStyle(task.statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(task.statusColor.opacity(0.15), in: Capsule())
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
