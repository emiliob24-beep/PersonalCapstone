//
//  AppDelegate.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/2/26.
//


import UIKit
import CloudKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        PersistenceController.shared.acceptShareInvitation(cloudKitShareMetadata)
    }
}