//
//  PlusApp.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import GroutLib
import GroutUI

@main
struct Gym_Routine_Tracker_Plus_App: App {
    let persistenceManager = PersistenceManager.shared

    @AppStorage(colorSchemeModeKey) var colorSchemeMode: ColorSchemeMode = .automatic

    @Environment(\.scenePhase) var scenePhase

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "App"
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                             persistenceManager.container.viewContext)
                .preferredColorScheme(colorSchemeMode.colorScheme)
        }
        .onChange(of: scenePhase) { _ in
            // save if: (1) app moved to background, and (2) changes are pending
            do {
                try persistenceManager.container.viewContext.save()
            } catch {
                logger.error("\(#function): \(error.localizedDescription)")
            }
        }
    }
}
