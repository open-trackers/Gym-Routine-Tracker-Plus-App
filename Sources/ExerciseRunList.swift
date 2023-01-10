//
//  ExerciseRunList.swift
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

import Compactor
import Tabler

import GroutLib
import GroutUI

struct ExerciseRunList: View {
    typealias Sort = TablerSort<ZExerciseRun>
    typealias Context = TablerContext<ZExerciseRun>
    typealias ProjectedValue = ObservedObject<ZExerciseRun>.Wrapper

    // MARK: - Parameters

    private var zRoutineRun: ZRoutineRun
    private var archiveStore: NSPersistentStore

    init(zRoutineRun: ZRoutineRun,
         archiveStore: NSPersistentStore)
    {
        self.zRoutineRun = zRoutineRun
        self.archiveStore = archiveStore

        let predicate = NSPredicate(format: "zRoutineRun = %@", zRoutineRun)
        let sortDescriptors = [NSSortDescriptor(keyPath: \ZExerciseRun.completedAt, ascending: true)]
        let request = makeRequest(ZExerciseRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: archiveStore)

        _exerciseRuns = FetchRequest<ZExerciseRun>(fetchRequest: request)
    }

    // MARK: - Locals

    let tcDur = TimeCompactor(ifZero: "", style: .short, roundSmallToWhole: false)

//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
//                                category: String(describing: RoutineRunView.self))

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest private var exerciseRuns: FetchedResults<ZExerciseRun>

    private var listConfig: TablerListConfig<ZExerciseRun> {
        TablerListConfig<ZExerciseRun>()
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 150, maximum: 300), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 80, maximum: 150), spacing: columnSpacing, alignment: .trailing),
        GridItem(.flexible(minimum: 70, maximum: 100), spacing: columnSpacing, alignment: .trailing),
    ] }

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   results: exerciseRuns)
            .navigationTitle(navigationTitle)
    }

    private func header(ctx _: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Exercise")
                .padding(columnPadding)
            Text("Intensity")
                .padding(columnPadding)
            Text("At")
                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func listRow(element: ZExerciseRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text(element.zExercise?.name ?? "")
                .padding(columnPadding)
            Text(formatIntensity(element.intensity))
                .padding(columnPadding)
            HStack(spacing: 0) {
                Text("@").foregroundStyle(.secondary)
                Text(getDuration(element.completedAt))
            }
            .padding(columnPadding)
        }
    }

    // MARK: - Properties

    private var navigationTitle: String {
        zRoutineRun.zRoutine?.wrappedName ?? "UNKNOWN"
    }

//    private var totalDurationStr: String {
//        tcDur.string(from: zRoutineRun.duration as NSNumber) ?? ""
//    }

    // MARK: - Helpers

    private func formatIntensity(_ intensity: Float) -> String {
        String(format: "%0.1f", intensity)
    }

    private func getDuration(_ completedAt: Date?) -> String {
        guard let startedAt = zRoutineRun.startedAt,
              let completedAt
        else { return "?" }

        let duration = completedAt.timeIntervalSince(startedAt)

        return tcDur.string(from: duration as NSNumber) ?? ""
    }
}

struct RoutineRunView_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceManager.getPreviewContainer().viewContext
        let archiveStore = PersistenceManager.getArchiveStore(ctx)!

        let routineArchiveID = UUID()
        let exerciseArchiveID1 = UUID()
        let exerciseArchiveID2 = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let completedAt1 = startedAt1.addingTimeInterval(120)
        let completedAt2 = completedAt1.addingTimeInterval(180)
        let intensity1: Float = 150.0
        let intensity2: Float = 200.0
        let duration1 = 500.0
        let zR = ZRoutine.create(ctx, routineName: "blah", routineArchiveID: routineArchiveID, toStore: archiveStore)
        let zRR = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        let zE1 = ZExercise.create(ctx, zRoutine: zR, exerciseName: "Lat Pulldown", exerciseArchiveID: exerciseArchiveID1, toStore: archiveStore)
        let zE2 = ZExercise.create(ctx, zRoutine: zR, exerciseName: "Rear Delt", exerciseArchiveID: exerciseArchiveID2, toStore: archiveStore)
        let zER1 = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE1, completedAt: completedAt1, intensity: intensity1, toStore: archiveStore)
        let zER2 = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE2, completedAt: completedAt2, intensity: intensity2, toStore: archiveStore)
        try! ctx.save()

        return NavigationStack {
            ExerciseRunList(zRoutineRun: zRR, archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}
