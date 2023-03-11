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
import StoreKit
import SwiftUI

import Compactor
import Tabler

import GroutLib
import GroutUI
import TrackerLib
import TrackerUI

struct RoutineRunList: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: GroutRouter

    typealias Sort = TablerSort<ZRoutineRun>
    typealias Context = TablerContext<ZRoutineRun>
    typealias ProjectedValue = ObservedObject<ZRoutineRun>.Wrapper

    // MARK: - Parameters

    private var archiveStore: NSPersistentStore

    internal init(archiveStore: NSPersistentStore) {
        self.archiveStore = archiveStore

        let predicate = ZRoutineRun.getPredicate(userRemoved: false)
        let sortDescriptors = ZRoutineRun.byStartedAt(ascending: false)
        let request = makeRequest(ZRoutineRun.self,
                                  predicate: predicate,
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

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()

    @FetchRequest private var routineRuns: FetchedResults<ZRoutineRun>

    private var listConfig: TablerListConfig<ZRoutineRun> {
        TablerListConfig<ZRoutineRun>(
            onDelete: userRemoveAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 180), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
    ] }

    private let tc = TimeCompactor(ifZero: "", style: .medium, roundSmallToWhole: false)

    // support for app review prompt
    @SceneStorage("has-been-prompted-for-app-review") private var hasBeenPromptedForAppReview = false
    private let minimumRunsForAppReviewAlert = 30

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
        return Text(Self.df.string(from: date))
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
        router.path.append(GroutRoute.exerciseRunList(zRoutineRun.uriRepresentation))
    }

    // NOTE: 'removes' matching records, where present, from both mainStore and archiveStore.
    private func userRemoveAction(at offsets: IndexSet) {
        do {
            for index in offsets {
                let zRoutineRun = routineRuns[index]
                guard let routineArchiveID = zRoutineRun.zRoutine?.routineArchiveID,
                      let startedAt = zRoutineRun.startedAt
                else { continue }

                try ZRoutineRun.userRemove(viewContext, routineArchiveID: routineArchiveID, startedAt: startedAt)
            }

            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct RoutineRunList_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let archiveStore = manager.getArchiveStore(ctx)!
        let routineArchiveID = UUID()

        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let startedAt2 = Date.now.addingTimeInterval(-10000)
        let duration2 = 400.0
        let zR = ZRoutine.create(ctx, routineArchiveID: routineArchiveID, routineName: "Chest & Shoulder", toStore: archiveStore)
        _ = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, duration: duration1, toStore: archiveStore)
        _ = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt2, duration: duration2, toStore: archiveStore)
        try! ctx.save()

        return NavigationStack {
            RoutineRunList(archiveStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}
