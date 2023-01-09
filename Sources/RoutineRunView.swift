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
import SwiftUI

import Tabler

import GroutLib
import GroutUI

struct RoutineRunView: View {
    typealias Sort = TablerSort<ZExerciseRun>
    typealias Context = TablerContext<ZExerciseRun>
    typealias ProjectedValue = ObservedObject<ZExerciseRun>.Wrapper

    // MARK: - Parameters

    private var routineArchiveID: UUID
    private var dateRange: ClosedRange<Date>
    private var archiveStore: NSPersistentStore

    init(routineArchiveID: UUID,
         dateRange: ClosedRange<Date>,
         archiveStore: NSPersistentStore)
    {
        self.routineArchiveID = routineArchiveID
        self.dateRange = dateRange
        self.archiveStore = archiveStore

        let request = NSFetchRequest<ZExerciseRun>(entityName: "ZExerciseRun")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ZExerciseRun.completedAt, ascending: true),
        ]
        request.affectedStores = [archiveStore]
        request.predicate = NSPredicate(format: "zExercise.zRoutine.routineArchiveID = %@ AND completedAt >= %@ AND completedAt <= %@", routineArchiveID.uuidString, dateRange.lowerBound as NSDate, dateRange.upperBound as NSDate)

        // TODO: needs to restrict to date range of routineRun

        _exerciseRuns = FetchRequest<ZExerciseRun>(fetchRequest: request)
    }

    // MARK: - Locals

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
//        GridItem(.flexible(minimum: 100, maximum: 200), spacing: columnSpacing, alignment: .leading),
    ] }

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   results: exerciseRuns)
            .navigationTitle("Routine \(String(routineArchiveID.uuidString.suffix(6)))")
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
}

struct RoutineRunView_Previews: PreviewProvider {
    static var previews: some View {
        let container = PersistenceManager.preview.container
        let context = container.viewContext
        let archiveStore = PersistenceManager.getArchiveStore(context)!

        try? context.deleter(entityName: "ZRoutineRun", inStore: archiveStore)
        try? context.deleter(entityName: "ZRoutine", inStore: archiveStore)
        try! context.save()

        let routineArchiveID = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let startedAt2 = Date.now.addingTimeInterval(-10000)
        let duration2 = 400.0
        let zR = ZRoutine.create(context, routineName: "blah", routineArchiveID: routineArchiveID, toStore: archiveStore)
        let zRR1 = ZRoutineRun.create(context, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        let zRR2 = ZRoutineRun.create(context, zRoutine: zR, startedAt: startedAt2, duration: duration2, toStore: archiveStore)
        try! context.save()

        // let routineArchiveID = zR.routineArchiveID
        let dateRange: ClosedRange<Date> = zRR1.dateRange

        return NavigationStack {
            RoutineRunView(routineArchiveID: routineArchiveID, dateRange: dateRange, archiveStore: archiveStore)
                .environment(\.managedObjectContext, context)
        }
    }
}
