//
//  ContentView.swift
//  PersonalCapstone
//
//  Created by Emilio Briceno on 7/21/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
                .tag(AppTab.history)

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(AppTab.schedule)

            GarageView()
                .tabItem { Label("Garage", systemImage: "car.fill") }
                .tag(AppTab.garage)

            // Family Garage tab is temporarily hidden for the App Store
            // submission — CloudKit sharing isn't reliably working yet
            // (see the CKShare investigation). Re-add once that's fixed.

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Color.appAccent)
        .environmentObject(appState)
        .task {
            NotificationManager.shared.requestAuthorization()
        }
    }
}
