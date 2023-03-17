//
//  Destination.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import GroutLib
import GroutUI
import TrackerUI

// handle routes for iOS-specific views here
struct Destination: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: GroutRouter
    @EnvironmentObject private var manager: CoreDataStack

    var route: GroutRoute

    var body: some View {
        switch route {
        case .routineRunList:
            HistoryView()
                .environmentObject(router)
                .environment(\.managedObjectContext, viewContext)
        case .routineRunRecent:
            if let mainStore = manager.getMainStore(viewContext) {
                RoutineRunRecent(withSettings: false, mainStore: mainStore)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Routine Run not available to display detail.")
            }
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
           let archiveStore = manager.getArchiveStore(viewContext),
           let title = zRoutineRun.zRoutine?.name
        {
            ExerciseRunList(zRoutineRun: zRoutineRun, inStore: archiveStore)
                .navigationTitle(title)
        } else {
            Text("Routine Run not available to display detail.")
        }
    }
}

struct Destination_Previews: PreviewProvider {
    static var previews: some View {
        Destination(route: .about)
    }
}
