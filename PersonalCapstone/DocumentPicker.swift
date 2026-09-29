//
//  DocumentPicker.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/3/26.
//


import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {

    /// Called with (fileData, fileExtension) once a file is picked.
    var onPick: (Data, String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .plainText])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Data, String) -> Void

        init(onPick: @escaping (Data, String) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // Files outside your app's sandbox (iCloud Drive, etc.) require
            // this security-scoped access before reading.
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.isEmpty ? "pdf" : url.pathExtension
                onPick(data, ext)
            } catch {
                print("Failed to read picked document: \(error)")
            }
        }
    }
}
