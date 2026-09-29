//
//  CloudSharingView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/2/26.
//


import SwiftUI
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {

    let share: CKShare
    let container: CKContainer
    let itemTitle: String

    func makeCoordinator() -> Coordinator {
        Coordinator(itemTitle: itemTitle)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let itemTitle: String

        init(itemTitle: String) {
            self.itemTitle = itemTitle
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            itemTitle
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error)")
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Share saved successfully")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("Stopped sharing this vehicle")
        }
    }
}
