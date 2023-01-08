//
//  HistoryView.swift
//  Gym Routine Tracker Plus
//
//  Created by Reed Esau on 1/8/23.
//

import SwiftUI

import Tabler

import GroutLib

struct HistoryView: View {
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
                   // header: header,
                   row: listRow,
                   // rowBackground: rowBackground,
                   results: routines)
//                    } else {
//                        TablerList(listConfig,
//                                   row: listRow,
//                                   rowBackground: rowBackground,
//                                   results: fruits)
//                    }
//                }
    }

    private var listConfig: TablerListConfig<Routine> {
        TablerListConfig<Routine>()
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 40, maximum: 60), spacing: columnSpacing, alignment: .leading),
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
