//
//  CoreDataNotesStorage.swift
//  memo
//
//  Created by Vladimir Pavlov on 11/06/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import CoreData

enum NotesStorageError: Error {
    case unknown
    case noteNotFound
    case calendarCannotBeAccessed
    case databaseContainsDuplicates
}

protocol INotesStorage {

    func notes(for searchQuery: String) throws -> [Note]
    func notes(for date: Date) throws -> [Note]
    func dailyNotesInfo() throws -> [Date: (UInt, UInt)]
    func note(with localID: UUID) throws -> Note
    func create(_ note: Note) throws -> Note
    func update(_ note: Note) throws -> Note
    func delete(_ note: Note) throws -> Bool
    func deleteAllNotes() throws
}

final class CoreDataNotesStorage: INotesStorage {

    private let persistentContainer: NSPersistentCloudKitContainer
    private let context: NSManagedObjectContext
    private let calendar = Calendar.autoupdatingCurrent

    init(persistentContainer: NSPersistentCloudKitContainer) {
        self.persistentContainer = persistentContainer
        self.context = persistentContainer.viewContext
    }

    func notes(for searchQuery: String) throws -> [Note] {
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteMO.creationDate, ascending: false)]
        if !searchQuery.isEmpty {
            let titlePredicate = NSPredicate(format: "%K contains[cd] %@", #keyPath(NoteMO.title), searchQuery)
            let contentPredicate = NSPredicate(format: "%K contains[cd] %@", #keyPath(NoteMO.content), searchQuery)
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
        }

        let notes = try context.fetch(request)
        return notes.map { memo.note(from: $0) }
    }

    func notes(for date: Date) throws -> [Note] {
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteMO.creationDate, ascending: true)]

        let dateFrom = calendar.startOfDay(for: date)
        guard let dateTo = calendar.date(byAdding: .day, value: 1, to: dateFrom) else {
            assertionFailure("Couldn't create tomorrow date")
            throw NotesStorageError.calendarCannotBeAccessed
        }
        let fromPredicate  = NSPredicate(format: "%K >= %@", argumentArray: [#keyPath(NoteMO.creationDate), dateFrom])
        let toPredicate = NSPredicate(format: "%K < %@", argumentArray: [#keyPath(NoteMO.creationDate), dateTo])
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fromPredicate, toPredicate])

        let notes = try self.context.fetch(request)
        let plainNotes = notes.map { memo.note(from: $0) }
        return plainNotes
    }

    func dailyNotesInfo() throws -> [Date: (UInt, UInt)] {
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()

        let notes = try self.context.fetch(request)

        var result: [Date: (UInt, UInt)] = [:]
        for note in notes {
            let startOfDay = calendar.startOfDay(for: note.creationDate!)
            if result[startOfDay] != nil {
                result[startOfDay]!.0 += 1
                result[startOfDay]!.1 += UInt(note.mood)
            } else {
                result[startOfDay] = (1, UInt(note.mood))
            }
        }
        return result
    }

    func note(with localID: UUID) throws -> Note {
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(NoteMO.localID), localID as CVarArg)

        let notes = try context.fetch(request)
        guard notes.count == 1 else { fatalError("Database contains duplicates") }
        guard let note = notes.first else { throw NotesStorageError.noteNotFound }
        let plainNote = memo.note(from: note)
        return plainNote
    }

    func create(_ note: Note) throws -> Note {
        let noteMO = NoteMO(context: self.context)
        updateNoteMO(noteMO, with: note)
        try self.context.save()
        return note
    }

    func update(_ note: Note) throws -> Note {
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(NoteMO.localID), note.localID as CVarArg)

        let notes = try self.context.fetch(request)
        guard notes.count == 1 else { fatalError("Database contains duplicates") }
        guard let noteMO = notes.first else { throw NotesStorageError.noteNotFound }
        updateNoteMO(noteMO, with: note)
        try self.context.save()
        return note
    }

    func delete(_ note: Note) throws -> Bool {
        let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(NoteMO.localID), note.localID as CVarArg)

        let notes = try self.context.fetch(request)
        guard notes.count <= 1 else { fatalError("Database contains duplicates") }
        guard let noteMO = notes.first else {
            throw NotesStorageError.noteNotFound
        }
        self.context.delete(noteMO)
        try self.context.save()
        return true
    }

    func deleteAllNotes() throws {
        let notesRequest: NSFetchRequest<NSFetchRequestResult> = NoteMO.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: notesRequest)
        try self.context.execute(deleteRequest)
        try self.context.save()
    }
}

// MARK: - Helpers

private func note(from noteMO: NoteMO) -> Note {
    let image: MemoImage?
    if let imageMO = noteMO.image {
        image = MemoImage(jpegData: imageMO.jpegData!)
    } else {
        image = nil
    }

    return Note(
        localID: noteMO.localID!,
        content: noteMO.content,
        creationDate: noteMO.creationDate!,
        image: image,
        mood: UInt8(noteMO.mood),
        title: noteMO.title
    )
}

private func updateNoteMO(_ noteMO: NoteMO, with note: Note) {
    noteMO.localID = note.localID
    noteMO.content = note.content
    noteMO.creationDate = note.creationDate
    noteMO.mood = Int16(note.mood)
    noteMO.title = note.title

    guard noteMO.image?.jpegData != note.image?.jpegData else {
        return
    }

    let context = noteMO.managedObjectContext!
    if let oldImageMO = noteMO.image {
        // Old images which are not related to a Note should not be stored in the database.
        context.delete(oldImageMO)
    }

    if let newImage = note.image {
        let newImageMO = Image(context: context)
        newImageMO.jpegData = newImage.jpegData
        noteMO.image = newImageMO
    } else {
        noteMO.image = nil
    }
}

private func findNote(with localID: UUID, in notes: [Note]) -> Note? {
    let filteredNotes = notes.filter { $0.localID == localID }
    assert(filteredNotes.count <= 1, "DB has duplicates")
    return filteredNotes.first
}
