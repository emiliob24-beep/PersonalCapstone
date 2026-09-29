//
//  AddVehicleView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 7/28/26.
//


//  Manual vehicle entry. VIN/plate lookup will replace the "auto-fill" gap here later —
//  for now this just gets a Vehicle into Core Data so you have something to test against.
//

import SwiftUI
import PhotosUI
internal import CoreData

struct AddVehicleView: View {

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var year: String = ""
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var trim: String = ""
    @State private var color: String = ""
    @State private var vin: String = ""
    @State private var licensePlate: String = ""
    @State private var odometer: String = ""

    @State private var isDecoding = false
    @State private var decodeErrorMessage: String?

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var pickedPhotoData: Data?

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty
        && !model.trimmingCharacters(in: .whitespaces).isEmpty
        && Int16(year) != nil
    }

    private var canLookUpVIN: Bool {
        vin.trimmingCharacters(in: .whitespaces).count == 17 && !isDecoding
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    if let photoData = pickedPhotoData, let uiImage = UIImage(data: photoData) {
                        HStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                            Button("Remove") {
                                pickedPhotoData = nil
                                photosPickerItem = nil
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        Label(pickedPhotoData == nil ? "Choose Photo" : "Choose Different Photo", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: photosPickerItem) { _, newItem in
                        loadPhoto(newItem)
                    }
                }

                Section("VIN Lookup") {
                    TextField("Enter 17-character VIN", text: $vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Button {
                        lookUpVIN()
                    } label: {
                        if isDecoding {
                            HStack {
                                ProgressView()
                                Text("Looking up...")
                            }
                        } else {
                            Label("Look Up Vehicle", systemImage: "magnifyingglass")
                        }
                    }
                    .disabled(!canLookUpVIN)

                    if let decodeErrorMessage {
                        Text(decodeErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Vehicle") {
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Trim (optional)", text: $trim)
                    TextField("Color (optional)", text: $color)
                }

                Section("Details") {
                    TextField("License Plate (optional)", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                    TextField("Current Odometer (mi)", text: $odometer)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Vehicle")
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

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run { pickedPhotoData = data }
            }
        }
    }

    private func lookUpVIN() {
        decodeErrorMessage = nil
        isDecoding = true

        Task {
            do {
                let result = try await VINDecoderService.decode(vin: vin)
                await MainActor.run {
                    make = result.make.capitalized
                    model = result.model
                    year = result.modelYear
                    if let series = result.series, !series.isEmpty {
                        trim = series
                    }
                    isDecoding = false
                }
            } catch {
                await MainActor.run {
                    decodeErrorMessage = error.localizedDescription
                    isDecoding = false
                }
            }
        }
    }

    private func save() {
        let vehicle = Vehicle(context: context)
        vehicle.id = UUID()
        vehicle.year = Int16(year) ?? 0
        vehicle.make = make
        vehicle.model = model
        vehicle.trim = trim.isEmpty ? nil : trim
        vehicle.color = color.isEmpty ? nil : color
        vehicle.vin = vin.isEmpty ? nil : vin
        vehicle.licensePlate = licensePlate.isEmpty ? nil : licensePlate
        vehicle.odometer = Int32(odometer) ?? 0
        vehicle.createdDate = Date()
        vehicle.photoData = pickedPhotoData

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save vehicle: \(error)")
        }
    }
}
