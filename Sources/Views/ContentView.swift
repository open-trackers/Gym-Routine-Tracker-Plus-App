//
//  ContentView.swift
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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    enum Tabs: Int {
        case routines = 0
        case history = 1
        case settings = 2
    }

    @SceneStorage("main-tab") private var selectedTab = 0
    @SceneStorage("main-routines-nav") private var routinesNavData: Data?
    @SceneStorage("main-history-nav") private var historyNavData: Data?
    @SceneStorage("main-settings-nav") private var settingsNavData: Data?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ContentView.self))

    var body: some View {
        TabView(selection: $selectedTab) {
            NavStack(name: "routines",
                     navData: $routinesNavData) {
                RoutineList()
            }
            .tabItem {
                Label("Routines", systemImage: "dumbbell")
            }
            .tag(Tabs.routines.rawValue)

            NavStack(name: "history",
                     navData: $historyNavData,
                     routineRunDetail: exerciseRunList) {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "fossil.shell")
            }
            .tag(Tabs.history.rawValue)

            NavStack(name: "settings",
                     navData: $settingsNavData) {
                PhoneSettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tabs.settings.rawValue)
        }
    }

    // used to inject view into NavStack
    @ViewBuilder
    private func exerciseRunList(_ routineRunUri: URL) -> some View {
        if let zRoutineRun = ZRoutineRun.get(viewContext, forURIRepresentation: routineRunUri),
           let archiveStore = PersistenceManager.getArchiveStore(viewContext)
        {
            ExerciseRunList(zRoutineRun: zRoutineRun, archiveStore: archiveStore)
        } else {
            Text("Routine Run not available to display detail.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceManager.getPreviewContainer().viewContext
        let routine = Routine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let e1 = Exercise.create(ctx, userOrder: 0)
        e1.name = "Lat Pulldown"
        e1.routine = routine
        let e2 = Exercise.create(ctx, userOrder: 1)
        e2.name = "Arm Curl"
        e2.routine = routine
        return ContentView()
            .environment(\.managedObjectContext, ctx)
    }
}
