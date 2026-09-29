//
//  AppState.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 8/18/26.
//

import Foundation
internal import CoreData
internal import Combine

enum AppTab {
    case history, schedule, garage, familyGarage, settings
}

final class AppState: ObservableObject {
    @Published var selectedVehicleID: NSManagedObjectID?
    @Published var selectedTab: AppTab = .garage
}
