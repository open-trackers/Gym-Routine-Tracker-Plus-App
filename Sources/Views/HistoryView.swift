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

import GroutLib
import GroutUI

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: GroutRouter

    // MARK: - Parameters

    // MARK: - Locals

    @State private var showAlert = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: HistoryView.self))

    // MARK: - Views

    var body: some View {
        RoutineRunList(archiveStore: archiveStore)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button(action: {
                        Haptics.play(.warning)
                        showAlert = true
                    }) {
                        Text("Clear")
                    }
                }
            }
            .alert("Are you sure?",
                   isPresented: $showAlert,
                   actions: {
                       Button("Delete", role: .destructive, action: clearHistoryAction)
                   },
                   message: {
                       Text("This will remove all historical data.")
                   })
            .navigationTitle(navigationTitle)
            .task(priority: .userInitiated, taskAction)
    }

    // MARK: - Properties

    private var navigationTitle: String {
        "History"
    }

    private var archiveStore: NSPersistentStore {
        guard let store = PersistenceManager.getArchiveStore(viewContext)
        else {
            fatalError("unable to resolve archive store")
        }
        return store
    }

    // MARK: - Actions

    private func clearHistoryAction() {
        do {
            // clear all 'z' records from both mainStore and archiveStore
            try PersistenceManager.clearZEntities(viewContext)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    @Sendable
    private func taskAction() async {
        logger.notice("\(#function) START")

        // transfer any 'Z' records from the 'Main' store to the 'Archive' store.

        await PersistenceManager.shared.container.performBackgroundTask { backgroundContext in
            do {
                try transferToArchive(backgroundContext)
                try backgroundContext.save()
            } catch {
                logger.error("\(#function): TRANSFER \(error.localizedDescription)")
            }
        }
        logger.notice("\(#function) END")
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
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

        return NavigationStack {
            HistoryView()
                .environment(\.managedObjectContext, ctx)
        }
    }
}
