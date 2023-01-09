//
//  RoutineRunList.swift
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

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                            category: "RoutineRunList")

struct RoutineRunList: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.managedObjectContext) private var viewContext

    typealias Sort = TablerSort<ZRoutineRun>
    typealias Context = TablerContext<ZRoutineRun>
    typealias ProjectedValue = ObservedObject<ZRoutineRun>.Wrapper

    // MARK: - Parameters

    private var archiveStore: NSPersistentStore

    internal init(archiveStore: NSPersistentStore) {
        self.archiveStore = archiveStore

        let request = NSFetchRequest<ZRoutineRun>(entityName: "ZRoutineRun")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ZRoutineRun.startedAt, ascending: false),
        ]
        request.affectedStores = [archiveStore]
        _routineRuns = FetchRequest<ZRoutineRun>(fetchRequest: request)
    }

    // MARK: - Locals

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    // timer used to refresh "2d ago, for 16.5m" on each Routine Cell
    @State private var now = Date()
    private let timer = Timer.publish(every: routineSinceUpdateSeconds,
                                      on: .main,
                                      in: .common).autoconnect()

    @FetchRequest private var routineRuns: FetchedResults<ZRoutineRun>

    private var listConfig: TablerListConfig<ZRoutineRun> {
        TablerListConfig<ZRoutineRun>()
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 40, maximum: 200), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 100, maximum: 200), spacing: columnSpacing, alignment: .leading),
    ] }

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   results: routineRuns)
            .navigationTitle("History")
            .onReceive(timer) { _ in
                self.now = Date.now
            }
    }

    private func header(ctx _: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Name")
//            Sort.columnTitle("Name", ctx, \.zRoutine?.name)
//                .onTapGesture { routineRuns.sortDescriptors = [tablerSort(ctx, \.zRoutine?.name)] }
                .padding(columnPadding)
            Text("Started")
//            Sort.columnTitle("Started", ctx, \.startedAt)
//                .onTapGesture { routineRuns.sortDescriptors = [tablerSort(ctx, \.startedAt)] }
                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func listRow(element: ZRoutineRun) -> some View {
        ZStack {
            LazyVGrid(columns: gridItems, alignment: .leading) {
                Text(element.zRoutine?.name ?? "")
                    .padding(columnPadding)
                SinceText(startedAt: element.startedAt, duration: element.duration, now: $now, compactorStyle: compactorStyle)
                    .padding(columnPadding)
            }
            .frame(maxWidth: .infinity)

            NavigationLink(destination: {
                RoutineRunView(zRoutineRun: element,
                               archiveStore: archiveStore)
                }) {
                    Rectangle().opacity(0.0)
                }
        }
    }

    // MARK: - Properties

    private var compactorStyle: TimeCompactor.Style {
        verticalSizeClass == .regular ? .short : .full
    }

    // MARK: - Actions
}

struct RoutineRunList_Previews: PreviewProvider {
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
        _ = ZRoutineRun.create(context, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        _ = ZRoutineRun.create(context, zRoutine: zR, startedAt: startedAt2, duration: duration2, toStore: archiveStore)
        try! context.save()

        return NavigationStack {
            RoutineRunList(archiveStore: archiveStore)
                .environment(\.managedObjectContext, context)
        }
    }
}
