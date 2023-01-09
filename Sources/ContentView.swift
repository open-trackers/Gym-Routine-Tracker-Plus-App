//
//  ContentView.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
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
                     navData: $historyNavData) {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "fossil.shell")
            }
            .tag(Tabs.history.rawValue)

            NavStack(name: "settings",
                     navData: $settingsNavData) {
                SettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tabs.settings.rawValue)
        }
    }
}

// TODO: four copies of each routine showing up; should be one!
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceManager.preview.container.viewContext
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
