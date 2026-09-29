//
//  ScheduleView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/20/26.
//

import SwiftUI
internal import CoreData

struct ScheduleView: View {

    @EnvironmentObject private var appState: AppState
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.createdDate, ascending: true)],
        animation: .default
    )
    private var vehicles: FetchedResults<Vehicle>

    @State private var showingAddTask = false
    @State private var taskToComplete: ScheduledTask?
    @State private var taskToEdit: ScheduledTask?

    private var selectedVehicle: Vehicle? {
        guard let id = appState.selectedVehicleID else { return nil }
        return vehicles.first { $0.objectID == id }
    }

    private var tasks: [ScheduledTask] {
        guard let vehicle = selectedVehicle else { return [] }
        let set = vehicle.scheduledTasks as? Set<ScheduledTask> ?? []
        return set.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
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
                } else if tasks.isEmpty {
                    emptyState
                } else {
                    List {
                        (Text(verbatim: "\(tasks.count) ") + Text(tasks.count == 1 ? "upcoming task" : "upcoming tasks"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .listRowSeparator(.hidden)

                        ForEach(tasks) { task in
                            ScheduledTaskRow(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    taskToEdit = task
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        taskToComplete = task
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.green)
                                }
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(selectedVehicle == nil)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                if let vehicle = selectedVehicle {
                    AddScheduledTaskView(vehicle: vehicle)
                }
            }
            .sheet(item: $taskToComplete) { task in
                CompleteTaskView(task: task)
            }
            .sheet(item: $taskToEdit) { task in
                EditScheduledTaskView(task: task)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No upcoming tasks")
                .font(.title2.bold())
            Text("Add a maintenance reminder to stay ahead of it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Task") {
                showingAddTask = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            if let id = tasks[index].id {
                NotificationManager.shared.cancelTaskNotifications(taskID: id)
            }
            context.delete(tasks[index])
        }
        try? context.save()
    }
}

// MARK: - Row + status styling

private struct ScheduledTaskRow: View {
    let task: ScheduledTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(LocalizedStringKey(task.title ?? "Untitled task"))
                    .font(.subheadline.bold())
                Spacer()
                Text(LocalizedStringKey(task.status ?? "Upcoming"))
                    .font(.caption.bold())
                    .foregroundStyle(task.statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.statusColor.opacity(0.15), in: Capsule())
            }

            HStack(spacing: 6) {
                if let dueDate = task.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                }
                if task.dueMileage > 0 {
                    Text(verbatim: "· ") + Text("In") + Text(verbatim: " \(task.dueMileage) ") + Text("mi")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if task.estimatedCost > 0 {
                (Text("Est.") + Text(verbatim: " \(task.estimatedCost.formatted(.currency(code: "USD")))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
