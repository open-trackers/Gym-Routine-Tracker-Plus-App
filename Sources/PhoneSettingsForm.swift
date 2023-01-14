//
//  PhoneSettingsForm.swift
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

struct PhoneSettingsForm: View {
    @Environment(\.managedObjectContext) private var viewContext

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: PhoneSettingsForm.self))

    var body: some View {
        SettingsForm(bottom: bottom)
    }

    private func bottom() -> some View {
        Section {
            ShareLink(item: getData(),
                      subject: Text("subject"), message: Text("message"), preview: SharePreview("Zip")) {
                Label("Export data", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("Data Export")
                .foregroundStyle(.tint)
        } footer: {
            Text("Exports to a zip file containing comma-separated-value (CSV) files, suitable for import into a spreadsheet.")
        }
    }

    // MARK: - Properties

    private var url: URL {
        URL(string: "https://yahoo.com")!
    }

    // MARK: - Actions

    private func getData() -> Data {
        // logger.notice("\(#function) ENTER")
        do {
            if let mainStore = PersistenceManager.getMainStore(viewContext),
               let archiveStore = PersistenceManager.getArchiveStore(viewContext),
               let data = try createZipArchive(viewContext, mainStore: mainStore, archiveStore: archiveStore)
            {
                return data
            }
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }

        // logger.notice("\(#function) EXIT")
        return Data()
    }
}

struct PhoneSettingsForm_Previews: PreviewProvider {
    static var previews: some View {
        PhoneSettingsForm()
    }
}
