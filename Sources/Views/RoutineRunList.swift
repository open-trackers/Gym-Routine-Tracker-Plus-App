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
import StoreKit

import Compactor
import Tabler

import GroutLib
import GroutUI

struct RoutineRunList: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme
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
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        // EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()

    @FetchRequest private var routineRuns: FetchedResults<ZRoutineRun>

    private var listConfig: TablerListConfig<ZRoutineRun> {
        TablerListConfig<ZRoutineRun>(
            onDelete: deleteAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 180), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
    ] }

    private let tc = TimeCompactor(ifZero: "", style: .medium, roundSmallToWhole: false)

    // support for app review prompt
    @SceneStorage("has-been-prompted-for-app-reviewc") private var hasBeenPromptedForAppReview = false
    private let minimumRunsForAppReviewAlert = 15

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   rowBackground: rowBackground,
                   results: routineRuns)
            .listStyle(.plain)
            .onAppear(perform: appearAction)
    }

    private func header(ctx _: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Routine")
                .padding(columnPadding)
            Text("Date")
                .padding(columnPadding)
            Text("Duration")
                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func listRow(element: ZRoutineRun) -> some View {
        Button(action: { detailAction(zRoutineRun: element) }) {
            LazyVGrid(columns: gridItems, alignment: .leading) {
                Text(element.zRoutine?.name ?? "")
                    .lineLimit(1)
                    .padding(columnPadding)
                startedAtText(element.startedAt)
                    .lineLimit(1)
                    .padding(columnPadding)
                durationText(element.duration)
                    .lineLimit(1)
//                ElapsedTimeText(elapsedSecs: element.duration)
                    .padding(columnPadding)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func rowBackground(_: ZRoutineRun) -> some View {
        EntityBackground(routineColor)
    }

    private func startedAtText(_ date: Date?) -> some View {
        guard let date else { return Text("") }
        return Text(df.string(from: date))
    }

    private func durationText(_ duration: TimeInterval) -> some View {
        Text(tc.string(from: duration as NSNumber) ?? "")
    }

    // MARK: - Properties

    // MARK: - Actions

    private func appearAction() {
        guard !hasBeenPromptedForAppReview,
              routineRuns.count >= minimumRunsForAppReviewAlert else { return }
        hasBeenPromptedForAppReview = true
        logger.notice("\(#function): attempting to request review, which may not work")
        requestReview()
    }

    private func detailAction(zRoutineRun: ZRoutineRun) {
        router.path.append(MyRoutes.routineRunDetail(zRoutineRun.uriRepresentation))
    }

    private func deleteAction(at offsets: IndexSet) {
        // NOTE: removing specified zRoutineRun records, where present, from both mainStore and archiveStore.

        do {
            for index in offsets {
                let zRoutineRun = routineRuns[index]

                guard let zRoutine = zRoutineRun.zRoutine,
                      let routineArchiveID = zRoutine.routineArchiveID,
                      let startedAt = zRoutineRun.startedAt
                else { continue }

                try ZRoutineRun.delete(viewContext, routineArchiveID: routineArchiveID, startedAt: startedAt, inStore: nil)
            }

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
