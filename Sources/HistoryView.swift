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

import Compactor
import Tabler

import GroutLib
import GroutUI

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                            category: "HistoryView")

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    // MARK: - Locals

    // MARK: - Views

    var body: some View {
        VStack {
            Button(action: purgeAction) {
                Label("Purge Archive", systemImage: "xmark")
            }

            RoutineRunList(archiveStore: archiveStore)
        }
        .task(priority: .utility, taskAction)
    }

    // MARK: - Properties

    private var archiveStore: NSPersistentStore {
        guard let store = PersistenceManager.getArchiveStore(viewContext)
        else {
            fatalError("unable to resolve archive store")
        }
        return store
    }

    // MARK: - Actions

    private func purgeAction() {
        do {
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
            HistoryView()
                .environment(\.managedObjectContext, context)
        }
    }
}
