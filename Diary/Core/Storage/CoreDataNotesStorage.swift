//
//  CoreDataNotesStorage.swift
//  Diary
//
//  Created by Vladimir Pavlov on 11/06/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation
import CoreData

final class CoreDataNotesStorage: INotesStorage {

  private let persistentContainer: NSPersistentContainer
  private let context: NSManagedObjectContext

  init(persistentContainer: NSPersistentContainer) {
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
    let plainNotes = notes.map { Diary.note(from: $0) }
    return plainNotes
  }

  func notes(for date: Date) throws -> [Note] {
    let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
    request.returnsObjectsAsFaults = false
    request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteMO.creationDate, ascending: true)]

    let calendar = Calendar.current
    let dateFrom = calendar.startOfDay(for: date)
    guard let dateTo = calendar.date(byAdding: .day, value: 1, to: dateFrom) else {
      assertionFailure("Couldn't create tomorrow date")
      throw NotesStorageError.calendarCannotBeAccessed
    }
    let fromPredicate  = NSPredicate(format: "%K >= %@", argumentArray: [#keyPath(NoteMO.creationDate), dateFrom])
    let toPredicate = NSPredicate(format: "%K < %@", argumentArray: [#keyPath(NoteMO.creationDate), dateTo])
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fromPredicate, toPredicate])

    let notes = try context.fetch(request)
    let plainNotes = notes.map { Diary.note(from: $0) }
    return plainNotes
  }

  func dailyNotesInfo() throws -> [Date: (UInt, UInt)] {
    let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
    request.returnsObjectsAsFaults = false

    let notes = try context.fetch(request)

    var result: [Date: (UInt, UInt)] = [:]
    for note in notes {
      let startOfDay = Calendar.current.startOfDay(for: note.creationDate!)
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
    let plainNote = Diary.note(from: note)
    return plainNote
  }

  func create(_ note: Note) throws -> Note {
    let noteMO = NoteMO(context: context)
    updateNoteMO(noteMO, with: note)
    try context.save()
    return note
  }

  func update(_ note: Note) throws -> Note {
    let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(format: "%K == %@", #keyPath(NoteMO.localID), note.localID as CVarArg)

    let notes = try context.fetch(request)
    guard notes.count == 1 else { fatalError("Database contains duplicates") }
    guard let noteMO = notes.first else { throw NotesStorageError.noteNotFound }
    updateNoteMO(noteMO, with: note)
    try context.save()
    return note
  }

  func updateOrCreate(_ notes: [Note]) throws {
    let localIDs = notes.map { $0.localID }
    let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(format: "%K IN %@", #keyPath(NoteMO.localID), localIDs)

    // Update existing notes
    let outdatedNotesMOs = try context.fetch(request)
    for outdatedNoteMO in outdatedNotesMOs {
      guard let note = findNote(with: outdatedNoteMO.localID!, in: notes) else { continue }
      updateNoteMO(outdatedNoteMO, with: note)
    }

    // Create notes which are not in DB yet
    let processedNotesIDs = outdatedNotesMOs.compactMap { $0.localID }
    let newNotes = notes.filter { !processedNotesIDs.contains($0.localID) }
    for newNote in newNotes {
      let newNoteMO = NoteMO(context: context)
      updateNoteMO(newNoteMO, with: newNote)
    }

    try context.save()
  }

  func outdatedNotes() throws -> [Note] {
    let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(format: "%K == false", #keyPath(NoteMO.isSynced))

    let notes = try context.fetch(request)
    let plainNotes = notes.map { Diary.note(from: $0) }
    return plainNotes
  }

  func delete(_ note: Note) throws -> Bool {
    let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
    request.returnsObjectsAsFaults = false
    request.predicate = NSPredicate(format: "%K == %@", #keyPath(NoteMO.localID), note.localID as CVarArg)

    let notes = try context.fetch(request)
    guard notes.count <= 1 else { fatalError("Database contains duplicates") }
    guard let noteMO = notes.first else {
      throw NotesStorageError.noteNotFound
    }
    context.delete(noteMO)
    try context.save()
    return true
  }

  func deleteNotesNotInArray(_ remoteIDs: [UInt]) throws {
    let request: NSFetchRequest<NoteMO> = NoteMO.fetchRequest()
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
      [
        // Don't delete notes weren't synced at least once
        NSPredicate(format: "%K != 0", #keyPath(NoteMO.remoteID)),
        NSPredicate(format: "NOT (%K IN %@)", #keyPath(NoteMO.remoteID), remoteIDs)
      ]
    )

    let notesMOs = try context.fetch(request)
    for noteMO in notesMOs {
      context.delete(noteMO)
    }
    try context.save()
  }

  func deleteAllNotes() throws {
    let notesRequest: NSFetchRequest<NSFetchRequestResult> = NoteMO.fetchRequest()
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: notesRequest)
    try context.execute(deleteRequest)
    try context.save()
  }
}

// MARK: - Helpers

private func note(from noteMO: NoteMO) -> Note {
  let image: MemoImage?
  if let imageMO = noteMO.image {
    image = MemoImage(jpegData: imageMO.jpegData, remoteURL: imageMO.remoteURL)
  } else {
    image = nil
  }

  return Note(localID: noteMO.localID!,
              remoteID: UInt(noteMO.remoteID),
              content: noteMO.content,
              creationDate: noteMO.creationDate!,
              image: image,
              mood: UInt8(noteMO.mood),
              title: noteMO.title,
              isSynced: noteMO.isSynced,
              toBeDeleted: noteMO.isToBeDeleted)
}

private func updateNoteMO(_ noteMO: NoteMO, with note: Note) {
  noteMO.localID = note.localID
  if let remoteID = note.remoteID {
    noteMO.remoteID = Int64(remoteID)
  }
  noteMO.content = note.content
  noteMO.creationDate = note.creationDate
  noteMO.mood = Int16(note.mood)
  noteMO.title = note.title
  noteMO.isSynced = note.isSynced
  noteMO.isToBeDeleted = note.toBeDeleted

  if noteMO.image?.jpegData == note.image?.jpegData,
    noteMO.image?.remoteURL == note.image?.remoteURL { return }
  let context = noteMO.managedObjectContext!

  if let oldImageMO = noteMO.image {
    // Old images which are not related to a Note should not be stored in the database.
    context.delete(oldImageMO)
  }

  if let newImage = note.image {
    let newImageMO = Image(context: context)
    newImageMO.jpegData = newImage.jpegData
    newImageMO.remoteURL = newImage.remoteURL
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
