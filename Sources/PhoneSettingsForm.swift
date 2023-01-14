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
    @EnvironmentObject private var router: MyRouter

    // MARK: - Locals

    @AppStorage(colorSchemeModeKey) var colorSchemeMode: ColorSchemeMode = .automatic
    @AppStorage(colorSchemeModeKey) var exportFormat: ExportFormat = .CSV

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: PhoneSettingsForm.self))

    // MARK: - Views

    var body: some View {
        SettingsForm {
            Section {
                Picker("Color", selection: $colorSchemeMode) {
                    ForEach(ColorSchemeMode.allCases, id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            } header: {
                Text("Color Scheme")
                    .foregroundStyle(.tint)
            }

            Section {
                Picker(selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { mode in
                        // Text("\(mode.defaultFileExtension.uppercased()) (\(mode.rawValue))")
                        // Text("\(mode.description) (\(mode.defaultFileExtension))")
                        Text(mode.defaultFileExtension.uppercased())
                            // Text(mode.description)
                            .tag(mode)
                    }
                } label: {
                    Text("Format")
                }
                .pickerStyle(.segmented)
                // .pickerStyle(MenuPickerStyle())
                ShareLink(item: getData(),
                          subject: Text("subject"), message: Text("message"), preview: SharePreview("Zip")) {
                    Label("Export data", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("Data Export")
                    .foregroundStyle(.tint)
            } footer: {
                Text("Exports to ZIP file as \(exportFormat.description) (\(exportFormat.rawValue)).")
            }

            Button(action: {
                router.path.append(MyRoutes.about)
            }) {
                Text("About \(appName)")
            }
        }
    }

    // MARK: - Properties

    private var appName: String {
        Bundle.main.appName ?? "unknown"
    }

    // MARK: - Actions

    private func getData() -> Data {
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
                return data
            }
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }

        logger.notice("\(#function) EXIT (failure)")
        return Data()
    }
}

struct PhoneSettingsForm_Previews: PreviewProvider {
    static var previews: some View {
        PhoneSettingsForm()
    }
}
