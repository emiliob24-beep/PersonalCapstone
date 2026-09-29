//
//  AddDocumentView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/21/26.
//
//  Metadata-only for the beta — title/category/date. File attachment
//  (fileData, via PhotosPicker/DocumentPicker) is a polish-phase addition.
//

import SwiftUI
import PhotosUI
internal import CoreData

struct AddDocumentView: View {

    @ObservedObject var vehicle: Vehicle

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var dateAdded = Date()

    @State private var pickedFileData: Data?
    @State private var pickedFileExtension: String?

    @State private var photosPickerItems: [PhotosPickerItem] = []
    @State private var showingDocumentPicker = false
    @State private var pickError: String?
    @State private var pickedPhotoCount = 0

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && pickedFileData != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("File") {
                    if pickedFileData != nil {
                        HStack {
                            Image(systemName: iconName)
                                .font(.title2)
                                .foregroundStyle(Color.appAccent)
                            attachmentSummary
                                .font(.subheadline)
                            Spacer()
                            Button("Remove") {
                                pickedFileData = nil
                                pickedFileExtension = nil
                                photosPickerItems = []
                                pickedPhotoCount = 0
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }

                    PhotosPicker(selection: $photosPickerItems, maxSelectionCount: 10, matching: .images) {
                        Label("Choose from Camera Roll", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: photosPickerItems) { _, newItems in
                        loadPhotos(newItems)
                    }

                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label("Choose PDF or File", systemImage: "doc.badge.plus")
                    }

                    if let pickError {
                        Text(pickError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Category (optional)", text: $category)
                    DatePicker("Date", selection: $dateAdded, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Document")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { data, ext in
                    pickedFileData = data
                    pickedFileExtension = ext
                    pickError = nil
                }
            }
        }
    }

    private var attachmentSummary: Text {
        if pickedPhotoCount > 1 {
            return Text(verbatim: "\(pickedPhotoCount) ") + Text("photos attached (combined into one PDF)")
        }
        return Text("File attached") + Text(verbatim: " (\(pickedFileExtension?.uppercased() ?? "FILE"))")
    }

    private var iconName: String {
        switch pickedFileExtension?.lowercased() {
        case "pdf": return "doc.richtext"
        case "jpg", "jpeg", "png", "heic": return "photo"
        default: return "doc"
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        pickError = nil

        Task {
            var images: [UIImage] = []

            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        continue
                    }
                    images.append(image)
                } catch {
                    continue
                }
            }

            guard !images.isEmpty else {
                await MainActor.run { pickError = "Couldn't load those photos. Try again." }
                return
            }

            if images.count == 1, let data = images[0].jpegData(compressionQuality: 0.9) {
                await MainActor.run {
                    pickedFileData = data
                    pickedFileExtension = "jpg"
                    pickedPhotoCount = 1
                }
            } else {
                let pdfData = combineImagesIntoPDF(images)
                await MainActor.run {
                    pickedFileData = pdfData
                    pickedFileExtension = "pdf"
                    pickedPhotoCount = images.count
                }
            }
        }
    }

    /// Combines multiple photos into a single multi-page PDF — one image
    /// per page, each page sized to match that image's aspect ratio.
    private func combineImagesIntoPDF(_ images: [UIImage]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            for image in images {
                context.beginPage()
                let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
                // Fit the image within the page while preserving aspect ratio.
                let imageAspect = image.size.width / image.size.height
                let pageAspect = pageRect.width / pageRect.height
                var drawRect = pageRect
                if imageAspect > pageAspect {
                    let height = pageRect.width / imageAspect
                    drawRect = CGRect(x: 0, y: (pageRect.height - height) / 2, width: pageRect.width, height: height)
                } else {
                    let width = pageRect.height * imageAspect
                    drawRect = CGRect(x: (pageRect.width - width) / 2, y: 0, width: width, height: pageRect.height)
                }
                image.draw(in: drawRect)
            }
        }
    }

    private func save() {
        guard let fileData = pickedFileData else { return }

        let document = Document(context: context)
        document.id = UUID()
        document.title = title
        document.category = category.isEmpty ? nil : category
        document.dateAdded = dateAdded
        document.fileData = fileData
        document.fileExtension = pickedFileExtension
        document.vehicle = vehicle

        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to save document: \(error)")
        }
    }
}
