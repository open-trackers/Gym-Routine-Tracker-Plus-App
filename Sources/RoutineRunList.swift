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

struct RoutineRunList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: MyRouter

    typealias Sort = TablerSort<ZRoutineRun>
    typealias Context = TablerContext<ZRoutineRun>
    typealias ProjectedValue = ObservedObject<ZRoutineRun>.Wrapper

    // MARK: - Parameters

    private var archiveStore: NSPersistentStore

    internal init(archiveStore: NSPersistentStore) {
        self.archiveStore = archiveStore

        let sortDescriptors = [NSSortDescriptor(keyPath: \ZRoutineRun.startedAt, ascending: false)]
        let request = makeRequest(ZRoutineRun.self,
                                  sortDescriptors: sortDescriptors,
                                  inStore: archiveStore)
        _routineRuns = FetchRequest<ZRoutineRun>(fetchRequest: request)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: RoutineRunList.self))

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
        TablerListConfig<ZRoutineRun>(
            onDelete: deleteAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 50, maximum: 300), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 100, maximum: 400), spacing: columnSpacing, alignment: .leading),
    ] }

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   rowBackground: rowBackground,
                   results: routineRuns)
            .listStyle(.plain)
            .onReceive(timer) { _ in
                self.now = Date.now
            }
    }

    private func header(ctx _: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Routine")
                .padding(columnPadding)
            Text("When")
                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func listRow(element: ZRoutineRun) -> some View {
        Button(action: { detailAction(zRoutineRun: element) }) {
            LazyVGrid(columns: gridItems, alignment: .leading) {
                Text(element.zRoutine?.name ?? "")
                    .padding(columnPadding)
                SinceText(startedAt: element.startedAt, duration: element.duration, now: $now, compactorStyle: compactorStyle)
                    .padding(columnPadding)
            }
            .frame(maxWidth: .infinity)
        }
        // .shadow(color: shadowColor, radius: 0.25, x: 0.25, y: 0.25)
    }

    private func rowBackground(_: ZRoutineRun) -> some View {
        EntityBackground(routineColor)
    }

    // MARK: - Properties

    private var compactorStyle: TimeCompactor.Style {
        verticalSizeClass == .regular ? .short : .full
    }

//    private var shadowColor: Color {
//        colorScheme == .light ? .black.opacity(0.33) : .clear
//    }

    // MARK: - Actions

    private func detailAction(zRoutineRun: ZRoutineRun) {
        router.path.append(MyRoutes.routineRunDetail(zRoutineRun.uriRepresentation))
    }

    private func deleteAction(at offsets: IndexSet) {
        for index in offsets {
            let element = routineRuns[index]
            viewContext.delete(element)
        }
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct RoutineRunList_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceManager.getPreviewContainer().viewContext
        let archiveStore = PersistenceManager.getArchiveStore(ctx)!
        let routineArchiveID = UUID()

        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let startedAt2 = Date.now.addingTimeInterval(-10000)
        let duration2 = 400.0
        let zR = ZRoutine.create(ctx, routineName: "Chest & Shoulder", routineArchiveID: routineArchiveID, toStore: archiveStore)
        _ = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        _ = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt2, duration: duration2, toStore: archiveStore)
        try! ctx.save()

        return NavigationStack {
            RoutineRunList(archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}