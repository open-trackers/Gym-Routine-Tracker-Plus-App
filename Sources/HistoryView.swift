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

import GroutLib

struct HistoryView: View {
    typealias Sort = TablerSort<Routine>
    typealias Context = TablerContext<Routine>
    typealias ProjectedValue = ObservedObject<Routine>.Wrapper

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.name, order: .forward)],
        animation: .default
    )
    private var routines: FetchedResults<Routine>

    var body: some View {
        // Sideways(minWidth: minWidth) {
        //   if headerize {
        TablerList(listConfig,
                   header: header,
                   row: listRow,
                   // rowBackground: rowBackground,
                   results: routines)
            .navigationTitle("History")
    }

    private func header(ctx: Binding<Context>) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Sort.columnTitle("Name", ctx, \.name)
                .onTapGesture { routines.sortDescriptors = [tablerSort(ctx, \.name)] }
                .padding(columnPadding)
//                    .background(headerBackground)
            Sort.columnTitle("Last Started", ctx, \.lastStartedAt)
                .onTapGesture { routines.sortDescriptors = [tablerSort(ctx, \.lastStartedAt)] }
                .padding(columnPadding)
//                    .background(headerBackground)
        }
    }

    private var listConfig: TablerListConfig<Routine> {
        TablerListConfig<Routine>()
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 40, maximum: 200), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 100, maximum: 200), spacing: columnSpacing, alignment: .leading),
    ] }

    private func listRow(element: Routine) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            rowItems(element: element)
        }
        // .modifier(listMenu(element))
    }

    @ViewBuilder
    private func rowItems(element: Routine) -> some View {
        Text(element.wrappedName)
            .padding(columnPadding)
        Text("\(String(describing: element.lastStartedAt))")
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
        let ctx = PersistenceManager.preview.container.viewContext
        let routine = Routine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let e1 = Exercise.create(ctx, userOrder: 0)
        e1.name = "Lat Pulldown"
        e1.routine = routine
        let e2 = Exercise.create(ctx, userOrder: 1)
        e2.name = "Arm Curl"
        e2.routine = routine
        return HistoryView()
            .environment(\.managedObjectContext, ctx)
    }
}
