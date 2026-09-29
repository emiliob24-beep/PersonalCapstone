//
//  PartsListView.swift
//  PersonalCapstone
//
//  Pushed from Settings: a standalone list of parts bought for a vehicle,
//  independent of any specific service record.
//

import SwiftUI
internal import CoreData

struct PartsListView: View {

    @ObservedObject var vehicle: Vehicle

    @Environment(\.managedObjectContext) private var context

    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Identifiable {
        case addPart
        case editPart(Part)

        var id: String {
            switch self {
            case .addPart: return "add"
            case .editPart(let part): return "edit-\(part.objectID)"
            }
        }
    }

    private var parts: [Part] {
        let set = vehicle.parts as? Set<Part> ?? []
        return set.sorted { ($0.datePurchased ?? .distantPast) > ($1.datePurchased ?? .distantPast) }
    }

    private var totalSpent: Double {
        parts.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        Group {
            if parts.isEmpty {
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
                        ForEach(parts) { part in
                            PartRow(part: part)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    activeSheet = .editPart(part)
                                }
                        }
                        .onDelete(perform: deleteParts)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Parts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .addPart
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addPart:
                AddPartView(vehicle: vehicle)
            case .editPart(let part):
                EditPartView(part: part)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Total Spent", value: totalSpent.formatted(.currency(code: "USD")))
            statCard(title: "Parts Logged", value: "\(parts.count)")
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
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No parts yet")
                .font(.title2.bold())
            Text("Keep track of parts you buy for this vehicle.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Part") {
                activeSheet = .addPart
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func deleteParts(at offsets: IndexSet) {
        for index in offsets {
            context.delete(parts[index])
        }
        try? context.save()
    }
}

private struct PartRow: View {
    let part: Part

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(part.name ?? "Part"))
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    if let date = part.datePurchased {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                    }
                    if part.quantity != 1 {
                        Text(verbatim: "· ") + Text("Qty") + Text(verbatim: " \(part.quantity)")
                    }
                    if let shop = part.purchasedFrom, !shop.isEmpty {
                        Text("· \(shop)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(part.cost.formatted(.currency(code: "USD")))
                .font(.subheadline.bold())
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
