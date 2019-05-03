//
//  INotesStorage.swift
//  memo
//
//  Created by Vladimir Pavlov on 25/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

enum NotesStorageError: Error {
  case unknown
  case noteNotFound
  case calendarCannotBeAccessed
  case databaseContainsDuplicates
}

protocol INotesStorage {

  func notes(for searchQuery: String) throws -> [Note]
  func notes(for date: Date) throws -> [Note]
  func outdatedNotes() throws -> [Note]
  func dailyNotesInfo() throws -> [Date: (UInt, UInt)]
  func note(with localID: UUID) throws -> Note
  func create(_ note: Note) throws -> Note
  func update(_ note: Note) throws -> Note
  func updateOrCreate(_ notes: [Note]) throws
  func delete(_ note: Note) throws -> Bool
  func deleteNotesNotInArray(_ remoteIDs: [UInt]) throws
  func deleteAllNotes() throws
}
