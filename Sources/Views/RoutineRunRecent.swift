//
//  RoutineRunRecent.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import GroutLib
import GroutUI
import TrackerLib
import TrackerUI

struct RoutineRunRecent: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: GroutRouter

    // MARK: - Parameters

    private let withSettings: Bool
    private var mainStore: NSPersistentStore

    internal init(withSettings: Bool,
                  mainStore: NSPersistentStore)
    {
        self.withSettings = withSettings
        self.mainStore = mainStore

        let predicate = ZRoutineRun.getPredicate(userRemoved: false)
        let sortDescriptors = ZRoutineRun.byStartedAt(ascending: false)
        let request = makeRequest(ZRoutineRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: mainStore)
        request.fetchLimit = 1
        _routineRuns = FetchRequest<ZRoutineRun>(fetchRequest: request)
    }

    // MARK: - Locals

    @FetchRequest private var routineRuns: FetchedResults<ZRoutineRun>

    // MARK: - Views

    var body: some View {
        VStack {
            if let routineRun {
                ExerciseRunList(zRoutineRun: routineRun, inStore: mainStore) {
                    Text(routineRun.zRoutine?.wrappedName ?? "")
                        .font(.largeTitle)
                }
            } else {
                Text("No recent activity. See ‘Full History’.")
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    Haptics.play()
                    router.path.append(GroutRoute.routineRunList)
                }) {
                    Text("Full History")
                }
            }
            if withSettings {
                ToolbarItem {
                    Button(action: {
                        router.path.append(GroutRoute.settings)
                    }) {
                        Text("Settings")
                    }
                }
            }
        }
        .navigationTitle("Recent")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Properties

    private var routineRun: ZRoutineRun? {
        routineRuns.first
    }
}

struct RecentRoutineRun_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let mainStore = manager.getMainStore(ctx)!

        let routineArchiveID = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let zR = ZRoutine.create(ctx, routineArchiveID: routineArchiveID, routineName: "blah", toStore: mainStore)
        let zRR = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: mainStore)
        let exerciseArchiveID1 = UUID()
        let exerciseArchiveID2 = UUID()
        let exerciseArchiveID3 = UUID()
        let completedAt1 = startedAt1.addingTimeInterval(116)
        let completedAt2 = completedAt1.addingTimeInterval(173)
        let completedAt3 = completedAt1.addingTimeInterval(210)
        let intensity1: Float = 150.0
        let intensity2: Float = 200.0
        let intensity3: Float = 50.0
        let zE1 = ZExercise.create(ctx, zRoutine: zR, exerciseArchiveID: exerciseArchiveID1, exerciseName: "Lat Pulldown", exerciseUnits: .kilograms, toStore: mainStore)
        let zE2 = ZExercise.create(ctx, zRoutine: zR, exerciseArchiveID: exerciseArchiveID2, exerciseName: "Rear Delt", exerciseUnits: .none, toStore: mainStore)
        let zE3 = ZExercise.create(ctx, zRoutine: zR, exerciseArchiveID: exerciseArchiveID3, exerciseName: "Arm Curl", exerciseUnits: .none, toStore: mainStore)
        _ = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE1, completedAt: completedAt1, intensity: intensity1, toStore: mainStore)
        let er2 = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE2, completedAt: completedAt2, intensity: intensity2, toStore: mainStore)
        _ = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE3, completedAt: completedAt3, intensity: intensity3, toStore: mainStore)
        er2.userRemoved = true
        try! ctx.save()

        return NavigationStack {
            RoutineRunRecent(withSettings: false, mainStore: mainStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}
