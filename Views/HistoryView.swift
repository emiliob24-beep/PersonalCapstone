//
//  HistoryView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/18/26.
//
//  The History tab: service records for whichever vehicle is selected
//  in Garage (tracked via AppState). Matches the stats-cards + list
//  layout from the original mockup.
//

import SwiftUI
internal import CoreData

struct HistoryView: View {

    @EnvironmentObject private var appState: AppState
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.createdDate, ascending: true)],
        animation: .default
    )
    private var vehicles: FetchedResults<Vehicle>

    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Identifiable {
        case addRecord
        case editRecord(ServiceRecord)
        case share(URL)

        var id: String {
            switch self {
            case .addRecord: return "add"
            case .editRecord(let record): return "edit-\(record.objectID)"
            case .share: return "share"
            }
        }
    }

    private var selectedVehicle: Vehicle? {
        guard let id = appState.selectedVehicleID else { return nil }
        return vehicles.first { $0.objectID == id }
    }

    private var records: [ServiceRecord] {
        guard let vehicle = selectedVehicle else { return [] }
        let set = vehicle.serviceRecords as? Set<ServiceRecord> ?? []
        return set.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private var totalSpent: Double {
        records.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        NavigationStack {
            Group {
                if selectedVehicle == nil {
                    ContentUnavailableView(
                        "No Vehicle Selected",
                        systemImage: "car.fill",
                        description: Text("Add a vehicle in the Garage tab first.")
                    )
                } else if records.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            statsRow
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        Section {
                            ForEach(records) { record in
                                ServiceRecordRow(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        activeSheet = .editRecord(record)
                                    }
                            }
                            .onDelete(perform: deleteRecords)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Service History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        exportPDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(selectedVehicle == nil)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .addRecord
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(selectedVehicle == nil)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addRecord:
                    if let vehicle = selectedVehicle {
                        AddServiceRecordView(vehicle: vehicle)
                    }
                case .editRecord(let record):
                    EditServiceRecordView(record: record)
                case .share(let url):
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Past 12 Months", value: totalSpent.formatted(.currency(code: "USD")))
            statCard(title: "Services Done", value: "\(records.count)")
        }
        .padding(.horizontal)
        .padding(.top, 8)
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No service records yet")
                .font(.title2.bold())
            Text("Log your first oil change, tire rotation, or repair.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Service Record") {
                activeSheet = .addRecord
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            context.delete(records[index])
        }
        try? context.save()
    }

    private func exportPDF() {
        guard let vehicle = selectedVehicle else { return }
        let data = ResalePDFGenerator.generate(for: vehicle)

        let fileName = "\(vehicle.make ?? "Vehicle")-\(vehicle.model ?? "")-ServiceHistory"
            .replacingOccurrences(of: " ", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")

        do {
            try data.write(to: url)
            activeSheet = .share(url)
        } catch {
            print("Failed to write PDF: \(error)")
        }
    }
}

private struct ServiceRecordRow: View {
    let record: ServiceRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(record.type ?? "Service"))
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    if let date = record.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                    }
                    Text(verbatim: "· \(record.mileage) ") + Text("mi")
                    if let shop = record.shop, !shop.isEmpty {
                        Text("· \(shop)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.cost.formatted(.currency(code: "USD")))
                .font(.subheadline.bold())
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
