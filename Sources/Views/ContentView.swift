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

let mainNavDataRoutineKey = "main-routines-nav"
let mainNavDataHistoryKey = "main-history-nav"
let mainNavDataSettingKey = "main-settings-nav"

struct ContentView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    @SceneStorage(tabbedViewSelectedTabKey) private var selectedTab = PortraitTab.routines.rawValue

//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
//                                category: String(describing: ContentView.self))

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let isPad = horizontalSizeClass == .regular && verticalSizeClass == .regular
            VStack {
                if isPad, isLandscape {
                    // enough vertical to show number pad, etc.
                    MainLandscape()
                } else {
                    MainPortrait()
                }
            }
        }
        .task(priority: .utility, taskAction)
        .onContinueUserActivity(startRoutineActivityType) {
            selectedTab = PortraitTab.routines.rawValue
            handleStartRoutineUA(viewContext, $0)
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
            .environmentObject(manager)
    }
}
