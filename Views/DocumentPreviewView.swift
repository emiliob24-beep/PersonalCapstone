//
//  DocumentPreviewView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/3/26.
//


import SwiftUI
import QuickLook

struct DocumentPreviewView: UIViewControllerRepresentable {

    let document: Document

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let previewURL: URL?

        init(document: Document) {
            guard let data = document.fileData else {
                previewURL = nil
                return
            }
            let ext = document.fileExtension?.isEmpty == false ? document.fileExtension! : "pdf"
            let fileName = (document.title?.isEmpty == false ? document.title! : "Document")
                .replacingOccurrences(of: "/", with: "-")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
                .appendingPathExtension(ext)
            try? data.write(to: url)
            previewURL = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            previewURL == nil ? 0 : 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            (previewURL ?? URL(fileURLWithPath: "")) as NSURL
        }
    }
}
