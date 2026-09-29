//
//  PersistenceController.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 7/23/26.
//
//  Sets up a private store and a shared store against the same iCloud
//  container, so CloudKit-shared vehicles can be mirrored separately
//  from ones this device owns.
//

internal import CoreData
import CloudKit

final class PersistenceController {

    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()

    let container: NSPersistentCloudKitContainer

    // Kept so the sharing UI (built next) can target the correct store
    // when creating or accepting a share.
    private(set) var privateStore: NSPersistentStore?
    private(set) var sharedStore: NSPersistentStore?

    private init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "PersonalCapstone")

        guard let privateDescription = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store description found — check that PersonalCapstone.xcdatamodeld exists.")
        }

        if inMemory {
            privateDescription.type = NSInMemoryStoreType
        } else {
            privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            let privateOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.emiliobriceno.PersonalCapstone"
            )
            privateOptions.databaseScope = .private
            privateDescription.cloudKitContainerOptions = privateOptions

            // Give the private store an explicit, predictable URL so we can
            // build the shared store's URL alongside it.
            guard let storeURL = privateDescription.url else {
                fatalError("Private store description has no URL")
            }
            let sharedStoreURL = storeURL.deletingLastPathComponent()
                .appendingPathComponent("PersonalCapstone-shared.sqlite")

            guard let sharedDescription = privateDescription.copy() as? NSPersistentStoreDescription else {
                fatalError("Could not copy private store description to build the shared store description")
            }
            sharedDescription.url = sharedStoreURL

            let sharedOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.emiliobriceno.PersonalCapstone"
            )
            sharedOptions.databaseScope = .shared
            sharedDescription.cloudKitContainerOptions = sharedOptions

            container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        }

        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }

            guard let self, !inMemory else { return }

            // Tag which store is which, using the URL we set above, so later
            // sharing code knows exactly where to look.
            if storeDescription.url == privateDescription.url {
                self.privateStore = self.container.persistentStoreCoordinator.persistentStore(for: storeDescription.url!)
            } else {
                self.sharedStore = self.container.persistentStoreCoordinator.persistentStore(for: storeDescription.url!)
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        if !inMemory {
            do {
                try container.viewContext.setQueryGenerationFrom(.current)
            } catch {
                print("Failed to pin viewContext to current generation: \(error)")
            }
        }
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Failed to save context: \(nsError), \(nsError.userInfo)")
        }
    }

    /// Called from AppDelegate when the user taps a share invite link.
    func acceptShareInvitation(_ metadata: CKShare.Metadata) {
        guard let sharedStore else {
            print("Shared store not yet initialized — can't accept invitation.")
            return
        }
        container.acceptShareInvitations(from: [metadata], into: sharedStore) { _, error in
            if let error {
                print("Failed to accept share invitation: \(error)")
            }
        }
    }
}
