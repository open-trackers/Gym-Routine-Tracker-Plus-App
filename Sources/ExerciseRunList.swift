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
    @Environment(\.managedObjectContext) private var viewContext

    typealias Sort = TablerSort<ZExerciseRun>
    typealias Context = TablerContext<ZExerciseRun>
    typealias ProjectedValue = ObservedObject<ZExerciseRun>.Wrapper

    // MARK: - Parameters

    private var archiveStore: NSPersistentStore
    private var zRoutineRun: ZRoutineRun

    init(zRoutineRun: ZRoutineRun, archiveStore: NSPersistentStore) {
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

    private let tcDur = TimeCompactor(ifZero: "", style: .short, roundSmallToWhole: false)

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ExerciseRunList.self))

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest private var exerciseRuns: FetchedResults<ZExerciseRun>

    private var listConfig: TablerListConfig<ZExerciseRun> {
        TablerListConfig<ZExerciseRun>(
            onDelete: deleteAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 70, maximum: 100), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 150, maximum: 300), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 80, maximum: 150), spacing: columnSpacing, alignment: .trailing),
    ] }

    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .short
        return df
    }()

    // MARK: - Views

    var body: some View {
        VStack {
            if let startedAt = zRoutineRun.startedAt,
               let dateStr = df.string(from: startedAt)
            {
                Text(dateStr)
            }
            TablerList(listConfig,
                       header: header,
                       row: listRow,
                       rowBackground: rowBackground,
                       results: exerciseRuns)
                .listStyle(.plain)
                .navigationTitle(navigationTitle)
        }
    }

    private func header(ctx _: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Elapsed")
                .padding(columnPadding)
            Text("Exercise")
                .padding(columnPadding)
            Text("Intensity")
                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func listRow(element: ZExerciseRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text(getTimeStr(element.completedAt))
                .padding(columnPadding)
            Text(element.zExercise?.name ?? "")
                .padding(columnPadding)
            Text(formatIntensity(element.intensity))
                .padding(columnPadding)
        }
    }

    private func rowBackground(_: ZExerciseRun) -> some View {
        EntityBackground(exerciseColor)
    }

    // MARK: - Properties

    private var navigationTitle: String {
        zRoutineRun.zRoutine?.wrappedName ?? "UNKNOWN"
    }

//    private var totalDurationStr: String {
//        tcDur.string(from: zRoutineRun.duration as NSNumber) ?? ""
//    }

    // MARK: - Actions

    private func deleteAction(at offsets: IndexSet) {
        for index in offsets {
            let element = exerciseRuns[index]
            viewContext.delete(element)
        }
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func formatIntensity(_ intensity: Float) -> String {
        String(format: "%0.1f", intensity)
    }

    private func getTimeStr(_ completedAt: Date?) -> String {
        guard let startedAt = zRoutineRun.startedAt,
              let completedAt
        else { return "?" }

        let duration = completedAt.timeIntervalSince(startedAt)

        let secondsPerDay: TimeInterval = 86400
        if duration >= secondsPerDay {
            // PUNT!
            return tcDur.string(from: duration as NSNumber) ?? ""
        }
        let t = Int(max(0, min(duration, TimeInterval(Int.max))))
        let hours = t / 3600
        let minutes = t / 60 % 60
        let seconds = t % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

struct ExerciseRunList_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceManager.getPreviewContainer().viewContext
        let archiveStore = PersistenceManager.getArchiveStore(ctx)!

        let routineArchiveID = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let zR = ZRoutine.create(ctx, routineName: "blah", routineArchiveID: routineArchiveID, toStore: archiveStore)
        let zRR = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        let exerciseArchiveID1 = UUID()
        let exerciseArchiveID2 = UUID()
        let completedAt1 = startedAt1.addingTimeInterval(116)
        let completedAt2 = completedAt1.addingTimeInterval(173)
        let intensity1: Float = 150.0
        let intensity2: Float = 200.0
        let zE1 = ZExercise.create(ctx, zRoutine: zR, exerciseName: "Lat Pulldown", exerciseArchiveID: exerciseArchiveID1, toStore: archiveStore)
        let zE2 = ZExercise.create(ctx, zRoutine: zR, exerciseName: "Rear Delt", exerciseArchiveID: exerciseArchiveID2, toStore: archiveStore)
        _ = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE1, completedAt: completedAt1, intensity: intensity1, toStore: archiveStore)
        _ = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE2, completedAt: completedAt2, intensity: intensity2, toStore: archiveStore)
        try! ctx.save()

        return NavigationStack {
            ExerciseRunList(zRoutineRun: zRR, archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}