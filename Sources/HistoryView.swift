//
//  HistoryView.swift
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

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                            category: "HistoryView")

struct HistoryView: View {
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
        VStack {
            Button(action: purgeAction) {
                Label("Purge Archive", systemImage: "xmark")
            }

            TablerList(listConfig,
                       header: header,
                       row: listRow,
                       results: routineRuns)
                .navigationTitle("History")
                .onReceive(timer) { _ in
                    self.now = Date.now
                }
        }
        .task(priority: .utility, taskAction)
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
                SinceText(startedAt: element.startedAt ?? Date(), duration: element.duration, now: $now, compactorStyle: .short)
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

    // MARK: - Actions

    private func purgeAction() {
        do {
            guard let archiveStore = PersistenceManager.getArchiveStore(viewContext) else {
                throw DataError.invalidStoreConfiguration(msg: "Cannot purge archive.")
            }
            try viewContext.deleter(entityName: "ZRoutineRun", inStore: archiveStore)
            try viewContext.deleter(entityName: "ZRoutine", inStore: archiveStore)
            try viewContext.deleter(entityName: "ZExerciseRun", inStore: archiveStore)
            try viewContext.deleter(entityName: "ZExercise", inStore: archiveStore)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    @Sendable
    private func taskAction() async {
        logger.notice("\(#function)")
        // transfer any 'Z' records from the 'Main' store to the 'Archive' store.
        // NOTE mirrored in HistoryView
        do {
            try transferToArchive(viewContext)
            try PersistenceManager.shared.save()
        } catch {
            logger.error("\(#function): TRANSFER \(error.localizedDescription)")
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
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
            HistoryView(archiveStore: archiveStore)
                .environment(\.managedObjectContext, context)
        }
    }
}
