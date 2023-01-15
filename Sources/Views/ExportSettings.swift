//
//  ExportSettings.swift
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

struct ExportSettings: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Locals

    @AppStorage(exportFormatKey) var exportFormat: ExportFormat = .CSV

    @State private var showFileExport = false
    @State private var zipDocument: ZipDocument?
    @State private var zipFileName: String?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: ExportSettings.self))

    // MARK: - Views

    var body: some View {
        Section {
            Button(action: exportAction) {
                Text("Export Data")
            }
            Picker("", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { mode in
                    Text(mode.defaultFileExtension.uppercased())
                        .tag(mode)
                }
            }
            .onChange(of: exportFormat) { _ in
                Haptics.play()
            }
            .pickerStyle(SegmentedPickerStyle())
        } header: {
            Text("Data Export")
                .foregroundStyle(.tint)
        } footer: {
            Text("Will export data to ZIP archive containing \(exportFormat.description) (\(exportFormat.rawValue)) files.")
        }
        .fileExporter(isPresented: $showFileExport,
                      document: zipDocument,
                      contentType: .zip,
                      defaultFilename: zipFileName) { result in
            switch result {
            case let .success(url):
                logger.notice("\(#function): saved to \(url)")
            case let .failure(error):
                logger.error("\(#function): \(error.localizedDescription)")
            }
            zipDocument = nil
            zipFileName = nil
        }
    }

    // MARK: - Actions

    private func exportAction() {
        Haptics.play()
        if let document = createZipDocument() {
            zipDocument = document
            zipFileName = generateTimestampFileName(prefix: "grt-", suffix: ".zip")
            showFileExport = true
        } else {
            logger.error("Unable to generate zip document, so not exporting.")
        }
    }

    // MARK: - Helpers

    private func createZipDocument() -> ZipDocument? {
        logger.notice("\(#function) ENTER")
        do {
            if let mainStore = PersistenceManager.getMainStore(viewContext),
               let archiveStore = PersistenceManager.getArchiveStore(viewContext),
               let data = try createZipArchive(viewContext,
                                               mainStore: mainStore,
                                               archiveStore: archiveStore,
                                               format: exportFormat)
            {
                logger.notice("\(#function) EXIT (success)")
                return ZipDocument(data: data)
            }
        } catch {
            logger.error("\(#function): ERROR \(error.localizedDescription)")
        }

        logger.notice("\(#function) EXIT (failure)")
        return nil
    }
}

struct ExportSettings_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ExportSettings()
        }
    }
}
