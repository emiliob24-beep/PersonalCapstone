//
//  Vehicle+Ownership.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 9/2/26.
//

internal import CoreData

extension Vehicle {
    var isSharedWithMe: Bool {
        objectID.persistentStore == PersistenceController.shared.sharedStore
    }
}
