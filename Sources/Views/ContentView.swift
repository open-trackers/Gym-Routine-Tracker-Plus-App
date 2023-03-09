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
import TrackerUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    enum Tabs: Int {
        case routines = 0
        case history = 1
        case settings = 2

        static let routinesNavUUID = UUID()
        static let historyNavUUID = UUID()
        static let settingsNavUUID = UUID()

        var uuid: UUID {
            switch self {
            case .routines:
                return Self.routinesNavUUID
            case .history:
                return Self.historyNavUUID
            case .settings:
                return Self.settingsNavUUID
            }
        }
    }

    @SceneStorage("main-tab") private var selectedTab = 0
    @SceneStorage("main-routines-nav") private var routinesNavData: Data?
    @SceneStorage("main-history-nav") private var historyNavData: Data?
    @SceneStorage("main-settings-nav") private var settingsNavData: Data?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ContentView.self))

    // NOTE: this proxy is duplicated in Daily Calorie Tracker Plus's ContentView.
    private var selectedProxy: Binding<Int> {
        Binding(get: { selectedTab },
                set: { nuTab in
                    if nuTab != selectedTab {
                        selectedTab = nuTab
                    } else {
                        guard let _nuTab = Tabs(rawValue: nuTab) else { return }
                        logger.debug("ContentView: detected tap on already-selected tab")
                        NotificationCenter.default.post(name: .trackerPopNavStack,
                                                        object: _nuTab.uuid)
                    }
                })
    }

    var body: some View {
        TabView(selection: selectedProxy) {
            GroutNavStack(navData: $routinesNavData,
                          stackIdentifier: Tabs.routinesNavUUID,
                          destination: destination)
            {
                RoutineList()
            }
            .tabItem {
                Label("Routines", systemImage: "dumbbell")
            }
            .tag(Tabs.routines.rawValue)

            GroutNavStack(navData: $historyNavData,
                          stackIdentifier: Tabs.historyNavUUID,
                          destination: destination)
            {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "fossil.shell")
            }
            .tag(Tabs.history.rawValue)

            GroutNavStack(navData: $settingsNavData,
                          stackIdentifier: Tabs.settingsNavUUID,
                          destination: destination)
            {
                PhoneSettingsForm()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tabs.settings.rawValue)
        }
        .task(priority: .utility, taskAction)
        .onContinueUserActivity(startRoutineActivityType) {
            selectedTab = Tabs.routines.rawValue
            handleStartRoutineUA(viewContext, $0)
        }
    }

    // handle routes for iOS-specific views here
    @ViewBuilder
    private func destination(_ router: GroutRouter, _ route: GroutRoute) -> some View {
        switch route {
        case let .exerciseRunList(routineRunUri):
            exerciseRunList(routineRunUri)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        default:
            GroutDestination(route)
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    @ViewBuilder
    private func exerciseRunList(_ routineRunUri: URL) -> some View {
        if let zRoutineRun: ZRoutineRun = ZRoutineRun.get(viewContext, forURIRepresentation: routineRunUri),
           let archiveStore = manager.getArchiveStore(viewContext)
        {
            ExerciseRunList(zRoutineRun: zRoutineRun, archiveStore: archiveStore)
        } else {
            Text("Routine Run not available to display detail.")
        }
    }

    @Sendable
    private func taskAction() async {
        await handleTaskAction(manager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = Routine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let e1 = Exercise.create(ctx, routine: routine, userOrder: 0)
        e1.name = "Lat Pulldown"
        let e2 = Exercise.create(ctx, routine: routine, userOrder: 1)
        e2.name = "Arm Curl"
        return ContentView()
            .environment(\.managedObjectContext, ctx)
    }
}
