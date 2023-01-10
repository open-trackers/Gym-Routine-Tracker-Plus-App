//
//  RoutineRunView.swift
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

import Tabler

import GroutLib
import GroutUI

struct RoutineRunView: View {
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
        GridItem(.flexible(minimum: 40, maximum: 300), spacing: columnSpacing, alignment: .leading),
        // GridItem(.flexible(minimum: 100, maximum: 200), spacing: columnSpacing, alignment: .leading),
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
            Text("Name")
//            Sort.columnTitle("Name", ctx, \.zExercise?.name)
//                .onTapGesture { exerciseRuns.sortDescriptors = [tablerSort(ctx, \.zExercise?.name)] }
                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func listRow(element: ZExerciseRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text(element.zExercise?.name ?? "")
                .padding(columnPadding)
        }
    }

    // MARK: - Properties

    private var navigationTitle: String {
        zRoutineRun.zRoutine?.wrappedName ?? "UNKNOWN"
    }
}

struct RoutineRunView_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceManager.getPreviewContainer().viewContext
        let archiveStore = PersistenceManager.getArchiveStore(ctx)!

        try? ctx.deleter(ZRoutineRun.self, inStore: archiveStore)
        try? ctx.deleter(ZRoutine.self, inStore: archiveStore)
        try! ctx.save()

        let routineArchiveID = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let startedAt2 = Date.now.addingTimeInterval(-10000)
        let duration2 = 400.0
        let zR = ZRoutine.create(ctx, routineName: "blah", routineArchiveID: routineArchiveID, toStore: archiveStore)
        let zRR1 = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        _ = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt2, duration: duration2, toStore: archiveStore)
        try! ctx.save()

        return NavigationStack {
            RoutineRunView(zRoutineRun: zRR1, archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}
