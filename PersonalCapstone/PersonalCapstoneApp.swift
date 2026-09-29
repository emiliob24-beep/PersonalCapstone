//
//  PersonalCapstoneApp.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 7/21/26.
//

import SwiftUI
internal import CoreData

@main
struct PersonalCapstoneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.locale, appLanguage == "system" ? .autoupdatingCurrent : Locale(identifier: appLanguage))
        }
    }
}
