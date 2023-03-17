//
//  MainPortrait.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import GroutLib
import GroutUI
import TrackerUI

enum PortraitTab: String {
    case routines
    case history
    case settings
}

let tabbedViewSelectedTabKey = "main-tab-str"

struct MainPortrait: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    @SceneStorage(tabbedViewSelectedTabKey) private var selectedTab = PortraitTab.routines.rawValue

    @SceneStorage(mainNavDataRoutineKey) private var routinesNavData: Data?
    @SceneStorage(mainNavDataHistoryKey) private var historyNavData: Data?
    @SceneStorage(mainNavDataSettingKey) private var settingsNavData: Data?

    // NOTE: this proxy is duplicated in Gym Routine Tracker Plus's ContentView.
    // QUESTION: can this be moved to TrackerUI somehow?
    private var selectedProxy: Binding<String> {
        Binding(get: { selectedTab },
                set: { nuTab in
                    if nuTab != selectedTab {
                        selectedTab = nuTab
                    } else {
                        NotificationCenter.default.post(name: .trackerPopNavStack,
                                                        object: nuTab)
                    }
                })
    }

    var body: some View {
        TabView(selection: selectedProxy) {
            GroutNavStack(navData: $routinesNavData,
                          stackIdentifier: PortraitTab.routines.rawValue,
                          destination: destination)
            {
                RoutineList()
            }
            .tabItem {
                Label("Gym Routines", systemImage: "dumbbell")
            }
            .tag(PortraitTab.routines.rawValue)

            GroutNavStack(navData: $historyNavData,
                          stackIdentifier: PortraitTab.history.rawValue,
                          destination: destination)
            {
                RoutineRunRecent()
            }
            .tabItem {
                Label("Recent", systemImage: "fossil.shell")
            }
            .tag(PortraitTab.history.rawValue)

            GroutNavStack(navData: $settingsNavData,
                          stackIdentifier: PortraitTab.settings.rawValue,
                          destination: destination)
            {
                PhoneSettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(PortraitTab.settings.rawValue)
        }
    }

    private func destination(router: GroutRouter, route: GroutRoute) -> some View {
        Destination(route: route)
            .environmentObject(router)
            .environment(\.managedObjectContext, viewContext)
    }
}

struct MainPortrait_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = Routine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let e1 = Exercise.create(ctx, routine: routine, userOrder: 0)
        e1.name = "Lat Pulldown"
        let e2 = Exercise.create(ctx, routine: routine, userOrder: 1)
        e2.name = "Arm Curl"
        return MainPortrait()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
