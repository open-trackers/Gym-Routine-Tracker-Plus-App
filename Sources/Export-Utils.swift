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
                             archiveStore _: NSPersistentStore,
                             format: ExportFormat = .CSV) throws -> Data?
{
    guard let archive = Archive(accessMode: .create)
    else { throw DataError.archiveCreationFailure }

    func blah<T: NSFetchRequestResult & Encodable & MAttributable>(_: T.Type,
                                                                   _ filePrefix: String,
                                                                   inStore: NSPersistentStore?) throws
    {
        let request = makeRequest(T.self, inStore: inStore)
        let results = try context.fetch(request)
        let data = try exportData(results, format: format)
        try archive.addEntry(with: "\(filePrefix).\(format.defaultFileExtension)",
                             type: .file,
                             uncompressedSize: Int64(data.count),
                             provider: { position, size -> Data in
                                 let range = Int(position) ..< Int(position) + size
                                 return data.subdata(in: range)
                             })
    }

    try blah(Routine.self, "routines", inStore: mainStore)
    try blah(Exercise.self, "exercises", inStore: mainStore)
    try blah(ZRoutine.self, "zroutines", inStore: mainStore)
    try blah(ZRoutineRun.self, "zroutineruns", inStore: mainStore)
    try blah(ZExercise.self, "zexercises", inStore: mainStore)
    try blah(ZExerciseRun.self, "zexerciseruns", inStore: mainStore)

    return archive.data
}
