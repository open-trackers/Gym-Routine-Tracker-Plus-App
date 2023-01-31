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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
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

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ExerciseRunList.self))

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        // EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest private var exerciseRuns: FetchedResults<ZExerciseRun>

    private var listConfig: TablerListConfig<ZExerciseRun> {
        TablerListConfig<ZExerciseRun>(
            onDelete: deleteAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 120), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 80), spacing: columnSpacing, alignment: .trailing),
    ] }

    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()

    private let tc = TimeCompactor(ifZero: "", style: .full, roundSmallToWhole: false)

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   footer: footer,
                   row: listRow,
                   rowBackground: rowBackground,
                   results: exerciseRuns)
            .listStyle(.plain)
            .navigationTitle(navigationTitle)
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
            elapsedText(element.completedAt)
                .padding(columnPadding)
            Text(element.zExercise?.name ?? "")
                .padding(columnPadding)
            intensityText(element.intensity, element.zExercise?.units)
                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func footer(ctx _: Binding<Context>) -> some View {
        HStack {
            GroupBox {
                startedAtText
                    .lineLimit(1)
            } label: {
                Text("Started")
                    .foregroundStyle(.tint)
                    .padding(.bottom, 3)
            }
            GroupBox {
                durationText(zRoutineRun.duration)
                    .lineLimit(1)
            } label: {
                Text("Duration")
                    .foregroundStyle(.tint)
                    .padding(.bottom, 3)
            }
        }
    }

    private func rowBackground(_: ZExerciseRun) -> some View {
        EntityBackground(exerciseColorDarkBg)
    }

    private var startedAtText: some View {
        VStack {
            if let startedAt = zRoutineRun.startedAt,
               let dateStr = df.string(from: startedAt)
            {
                Text(dateStr)
            } else {
                EmptyView()
            }
        }
    }

    private func elapsedText(_ completedAt: Date?) -> some View {
        ElapsedTimeText(elapsedSecs: getDuration(completedAt) ?? 0, timeElapsedFormat: timeElapsedFormat)
    }

    private func intensityText(_ intensity: Float, _ units: Int16?) -> some View {
        Text(formattedIntensity(intensity, units))
            .modify {
                if #available(iOS 16.1, watchOS 9.1, *) {
                    $0.fontDesign(.monospaced)
                } else {
                    $0.monospaced()
                }
            }
    }

    private func durationText(_ duration: TimeInterval) -> some View {
        Text(tc.string(from: duration as NSNumber) ?? "")
    }

    // MARK: - Properties

    // select a formatter to accommodate the duration
    private var timeElapsedFormat: TimeElapsedFormat {
        let secondsPerHour: TimeInterval = 3600
        return zRoutineRun.duration < secondsPerHour ? .mm_ss : .hh_mm_ss
    }

    private var navigationTitle: String {
        zRoutineRun.zRoutine?.wrappedName ?? "UNKNOWN"
    }

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

    private func formattedIntensity(_ intensity: Float, _ units: Int16?) -> String {
        let _units = units != nil ? Units(rawValue: units!) ?? .none : .none
        return formatIntensity(intensity, units: _units, withUnits: true, isFractional: true)
    }

    private func getDuration(_ completedAt: Date?) -> TimeInterval? {
        guard let startedAt = zRoutineRun.startedAt,
              let completedAt
        else { return nil }

        return completedAt.timeIntervalSince(startedAt)
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
        let zE1 = ZExercise.create(ctx, zRoutine: zR, exerciseName: "Lat Pulldown", exerciseUnits: .kilograms, exerciseArchiveID: exerciseArchiveID1, toStore: archiveStore)
        let zE2 = ZExercise.create(ctx, zRoutine: zR, exerciseName: "Rear Delt", exerciseUnits: .none, exerciseArchiveID: exerciseArchiveID2, toStore: archiveStore)
        _ = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE1, completedAt: completedAt1, intensity: intensity1, toStore: archiveStore)
        _ = ZExerciseRun.create(ctx, zRoutineRun: zRR, zExercise: zE2, completedAt: completedAt2, intensity: intensity2, toStore: archiveStore)
        try! ctx.save()

        return NavigationStack {
            ExerciseRunList(zRoutineRun: zRR, archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}
