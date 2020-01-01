//
//  NoteService.swift
//  memo
//
//  Created by Vladimir Pavlov on 25/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

protocol INoteService {

  func fetchNotes(for searchQuery: String) throws -> [Note]
  func fetchNotes(for date: Date) throws -> [Note]
  func dailyNotesInfo() throws -> [Date: (UInt, UInt)]
  func note(with localID: UUID) throws -> Note
  func create(_ note: Note, completion: @escaping (Result<Note>) -> Void)
  func update(_ note: Note, completion: @escaping (Result<Note>) -> Void)
  func deleteAllNotes(completion: @escaping (Result<Void>) -> Void)
  func image(with url: URL, for note: Note, completion: @escaping (Result<Data>) -> Void)

  func isValid(note: Note) -> Bool
}

final class NoteService: INoteService {

  private let notesStorage: INotesStorage

  init(notesStorage: INotesStorage) {
    self.notesStorage = notesStorage
  }

  func fetchNotes(for searchQuery: String) throws -> [Note] {
    return try self.notesStorage.notes(for: searchQuery)
  }

  func fetchNotes(for date: Date) throws -> [Note] {
    return try self.notesStorage.notes(for: date)
  }

  func dailyNotesInfo() throws -> [Date: (UInt, UInt)] {
    return try self.notesStorage.dailyNotesInfo()
  }

  func note(with localID: UUID) throws -> Note {
    return try self.notesStorage.note(with: localID)
  }

  func create(_ note: Note, completion: @escaping (Result<Note>) -> Void) {
    do {
      let createdNote = try notesStorage.create(note)
      completion(.success(createdNote))
    } catch {
      completion(.failure(error))
    }
  }

  func update(_ note: Note, completion: @escaping (Result<Note>) -> Void) {
    do {
      let updatedNote = try notesStorage.update(note)
      completion(.success(updatedNote))
    } catch {
      completion(.failure(error))
    }
  }

  func deleteAllNotes(completion: @escaping (Result<Void>) -> Void) {
    do {
      try notesStorage.deleteAllNotes()
      completion(.success(()))
    } catch {
      completion(.failure(error))
    }
  }

  func image(with url: URL,
             for note: Note,
             completion: @escaping (Result<Data>) -> Void) {
    if let jpegData = note.image?.jpegData {
      completion(.success(jpegData))
    } else {
      completion(.failure(NSError()))
    }
  }

  func isValid(note: Note) -> Bool {
    if let title = note.title, !title.isEmpty { return true }
    if note.image != nil { return true }
    if let content = note.content, !content.isEmpty { return true }
    return false
  }
}
