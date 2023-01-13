//
//  ContentView.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import GroutLib
import GroutUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    enum Tabs: Int {
        case routines = 0
        case history = 1
        case settings = 2
    }

    @SceneStorage("main-tab") private var selectedTab = 0
    @SceneStorage("main-routines-nav") private var routinesNavData: Data?
    @SceneStorage("main-history-nav") private var historyNavData: Data?
    @SceneStorage("main-settings-nav") private var settingsNavData: Data?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavStack(name: "routines",
                     navData: $routinesNavData) {
                RoutineList()
            }
            .tabItem {
                Label("Routines", systemImage: "dumbbell")
            }
            .tag(Tabs.routines.rawValue)

            NavStack(name: "history",
                     navData: $historyNavData,
                     routineRunDetail: exerciseRunList) {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "fossil.shell")
            }
            .tag(Tabs.history.rawValue)

            NavStack(name: "settings",
                     navData: $settingsNavData) {
                SettingsForm(onExport: exportAction)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tabs.settings.rawValue)
        }
    }

    // used to inject view into NavStack
    @ViewBuilder
    private func exerciseRunList(_ routineRunUri: URL) -> some View {
        if let zRoutineRun = ZRoutineRun.get(viewContext, forURIRepresentation: routineRunUri),
           let archiveStore = PersistenceManager.getArchiveStore(viewContext)
        {
            ExerciseRunList(zRoutineRun: zRoutineRun, archiveStore: archiveStore)
        } else {
            Text("Routine Run not available to display detail.")
        }
    }

    // MARK: - Actions

    private func exportAction() {
//        if let data = try? packageRebalance(params: ds.params,
//                                            tradingAllocations: tradingAllocations,
//                                            nonTradingAllocations: nonTradingAllocations,
//                                            mpurchases: mpurchases,
//                                            msales: msales) {
//            #if os(macOS)
//            NSSavePanel.saveData(data, name: "rebalance", ext: "zip", completion: { _ in })
//            #endif
//        }
    }

//    public func packageRebalance(params: BaseParams,
//                                 tradingAllocations: [MRebalanceAllocation],
//                                 nonTradingAllocations: [MRebalanceAllocation],
//                                 mpurchases: [MRebalancePurchase],
//                                 msales: [MRebalanceSale]) throws -> Data {
//        guard let archive = Archive(accessMode: .create)
//        else { throw FlowBaseError.archiveCreateFailure }
//
//        let fileExt = rebalancePackageFormat.defaultFileExtension!
//
//        let trading = try exportData(tradingAllocations, format: rebalancePackageFormat)
//        try archive.addEntry(with: "trading-allocations.\(fileExt)",
//                             type: .file,
//                             uncompressedSize: Int64(trading.count),
//                             provider: { position, size -> Data in
//            let range = Int(position) ..< Int(position) + size
//            return trading.subdata(in: range)
//        })
//
//        let nonTrading = try exportData(nonTradingAllocations, format: rebalancePackageFormat)
//        try archive.addEntry(with: "non-trading-allocations.\(fileExt)",
//                             type: .file,
//                             uncompressedSize: Int64(nonTrading.count),
//                             provider: { position, size -> Data in
//            let range = Int(position) ..< Int(position) + size
//            return nonTrading.subdata(in: range)
//        })
//
//        let exportedPurchases = try exportData(mpurchases, format: rebalancePackageFormat)
//        try archive.addEntry(with: "purchases.\(fileExt)",
//                             type: .file,
//                             uncompressedSize: Int64(exportedPurchases.count),
//                             provider: { position, size -> Data in
//            let range = Int(position) ..< Int(position) + size
//            return exportedPurchases.subdata(in: range)
//        })
//
//        let exportedSales = try exportData(msales, format: rebalancePackageFormat)
//        try archive.addEntry(with: "sales.\(fileExt)",
//                             type: .file,
//                             uncompressedSize: Int64(exportedSales.count),
//                             provider: { position, size -> Data in
//            let range = Int(position) ..< Int(position) + size
//            return exportedSales.subdata(in: range)
//        })
//
//        let paramsData: Data = try StorageManager.encodeToJSON(params)
//        try archive.addEntry(with: "params.json",
//                             type: .file,
//                             uncompressedSize: Int64(paramsData.count),
//                             provider: { position, size -> Data in
//            let range = Int(position) ..< Int(position) + size
//            return paramsData.subdata(in: range)
//        })
//
//        return archive.data!
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let ctx = PersistenceManager.getPreviewContainer().viewContext
        let routine = Routine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let e1 = Exercise.create(ctx, userOrder: 0)
        e1.name = "Lat Pulldown"
        e1.routine = routine
        let e2 = Exercise.create(ctx, userOrder: 1)
        e2.name = "Arm Curl"
        e2.routine = routine
        return ContentView()
            .environment(\.managedObjectContext, ctx)
    }
}
