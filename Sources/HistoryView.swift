//
//  HistoryView.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import Tabler

import GroutUI
import GroutLib

struct HistoryView: View {
    typealias Sort = TablerSort<ZRoutineRun>
    typealias Context = TablerContext<ZRoutineRun>
    typealias ProjectedValue = ObservedObject<ZRoutineRun>.Wrapper

    private let columnSpacing: CGFloat = 10

    // timer used to refresh "2d ago, for 16.5m" on each Routine Cell
    @State private var now = Date()
    private let timer = Timer.publish(every: routineSinceUpdateSeconds,
                                      on: .main,
                                      in: .common).autoconnect()
    
    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.zRoutine?.name, order: .forward)],
        animation: .default
    )
    private var routineRuns: FetchedResults<ZRoutineRun>

    var body: some View {
        // Sideways(minWidth: minWidth) {
        //   if headerize {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   // rowBackground: rowBackground,
                   results: routineRuns)
            .navigationTitle("History")
            .onReceive(timer) { _ in
                self.now = Date.now
            }
    }

    private func header(ctx: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Sort.columnTitle("Name", ctx, \.zRoutine?.name)
                .onTapGesture { routineRuns.sortDescriptors = [tablerSort(ctx, \.zRoutine?.name)] }
                .padding(columnPadding)
//                    .background(headerBackground)
            Sort.columnTitle("Started", ctx, \.startedAt)
                .onTapGesture { routineRuns.sortDescriptors = [tablerSort(ctx, \.startedAt)] }
                .padding(columnPadding)
//                    .background(headerBackground)
        }
    }

    private var listConfig: TablerListConfig<ZRoutineRun> {
        TablerListConfig<ZRoutineRun>()
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 40, maximum: 200), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 100, maximum: 200), spacing: columnSpacing, alignment: .leading),
    ] }

    private func listRow(element: ZRoutineRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            rowItems(element: element)
        }
        // .modifier(listMenu(element))
    }

    @ViewBuilder
    private func rowItems(element: ZRoutineRun) -> some View {
        Text(element.zRoutine?.name ?? "")
            .padding(columnPadding)
        SinceText(startedAt: element.startedAt ?? Date(), duration: element.duration, now: $now, compactorStyle: .short)
            .padding(columnPadding)
    }

//    private func listMenu(_ fruit: Fruit) -> EditDetailerSwipeMenu<Fruit> {
//            EditDetailerSwipeMenu(fruit,
//                                  canDelete: detailerConfig.canDelete,
//                                  onDelete: detailerConfig.onDelete,
//                                  canEdit: detailerConfig.canEdit,
//                                  onEdit: editAction)
//        }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let container = PersistenceManager.preview.container
        let ctx = container.viewContext
        let archiveStore = PersistenceManager.getArchiveStore(ctx)!

        let routineArchiveID = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let startedAt2 = Date.now.addingTimeInterval(-10000)
        let duration2 = 400.0
        let zR = ZRoutine.create(ctx, routineName: "blah", routineArchiveID: routineArchiveID, toStore: archiveStore)
        _ = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        _ = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt2, duration: duration2, toStore: archiveStore)
        try! ctx.save()
        
        return HistoryView()
            .environment(\.managedObjectContext, ctx)
    }
}
