//
//  Export-Utils.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import ZIPFoundation

import GroutLib

public func createZipArchive(_ context: NSManagedObjectContext,
                             mainStore: NSPersistentStore,
                             archiveStore: NSPersistentStore,
                             format: ExportFormat = .CSV) throws -> Data?
{
    guard let archive = Archive(accessMode: .create)
    else { throw TrackerError.archiveCreationFailure }

    func makeDelimFile<T: NSFetchRequestResult & Encodable & MAttributable>(_: T.Type,
                                                                            inStore: NSPersistentStore?) throws
    {
        let request = makeRequest(T.self, inStore: inStore)
        let results = try context.fetch(request)
        let data = try exportData(results, format: format)
        let fileName = "\(T.fileNamePrefix).\(format.defaultFileExtension)"
        try archive.addEntry(with: fileName,
                             type: .file,
                             uncompressedSize: Int64(data.count),
                             provider: { position, size -> Data in
                                 let range = Int(position) ..< Int(position) + size
                                 return data.subdata(in: range)
                             })
    }

    try makeDelimFile(Routine.self, inStore: mainStore)
    try makeDelimFile(Exercise.self, inStore: mainStore)

    // NOT WORKING: Local function 'makeDelimFile(_:inStore:)' requires that 'NSManagedObject' conform to 'Encodable'
    // [ZRoutine.self, ZRoutineRun.self, ZExercise.self, ZExerciseRun.self].forEach {
    //    try makeDelimFile($0, inStore: archiveStore)
    // }

    try makeDelimFile(ZRoutine.self, inStore: archiveStore)
    try makeDelimFile(ZRoutineRun.self, inStore: archiveStore)
    try makeDelimFile(ZExercise.self, inStore: archiveStore)
    try makeDelimFile(ZExerciseRun.self, inStore: archiveStore)

    return archive.data
}
