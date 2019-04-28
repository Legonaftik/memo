//
//  NoteService.swift
//  Diary
//
//  Created by Vladimir Pavlov on 25/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

protocol INoteService {

  func syncNotes(token: String?, completion: @escaping (Result<Void>) -> Void)
  func fetchNotes(for searchQuery: String) throws -> [Note]
  func fetchNotes(for date: Date) throws -> [Note]
  func dailyNotesInfo() throws -> [Date: (UInt, UInt)]
  func note(with localID: UUID) throws -> Note
  func create(_ note: Note, token: String?, completion: @escaping (Result<Note>) -> Void)
  func update(_ note: Note, token: String?, completion: @escaping (Result<Note>) -> Void)
  func deleteAllNotes(token: String, completion: @escaping (Result<Void>) -> Void)
  func image(with url: URL, for note: Note, completion: @escaping (Result<Data>) -> Void)

  func resetSyncState()
  func isValid(note: Note) -> Bool
}

final class NoteService: INoteService {

  private let networkClient: INetworkClient
  private let notesStorage: INotesStorage
  private let userPreferencesStorage: IUserPreferencesStorage

  init(networkClient: INetworkClient,
       notesStorage: INotesStorage,
       userPreferencesStorage: IUserPreferencesStorage) {
    self.networkClient = networkClient
    self.notesStorage = notesStorage
    self.userPreferencesStorage = userPreferencesStorage
  }

  func syncNotes(token: String?, completion: @escaping (Result<Void>) -> Void) {
    guard let token = token else {
      completion(.failure(NotesStorageError.unknown))
      return
    }

    self.networkClient.serverTime { [unowned self] serverTimeResult in
      switch serverTimeResult {
      case .failure(let error):
        completion(.failure(error))
      case .success(let serverTime):
        do {
          let outdatedNotes = try self.notesStorage.outdatedNotes()

          self.updateOrDeleteOutdatedNotes(outdatedNotes, token: token) {
            let beginDate = self.userPreferencesStorage.lastNotesSyncDate
            self.networkClient.notes(token: token, beginDate: beginDate) { notesResponseResult in
              switch notesResponseResult {
              case .failure(let error):
                completion(.failure(error))
              case .success(let notesResponse):
                let syncedNotes = notesResponse.updated.map { note -> Note in
                  var syncedNote = note
                  syncedNote.isSynced = true
                  return syncedNote
                }

                do {
                  try self.notesStorage.updateOrCreate(syncedNotes)
                  try self.notesStorage.deleteNotesNotInArray(notesResponse.remoteIDs)
                  self.userPreferencesStorage.lastNotesSyncDate = serverTime
                  completion(.success(()))
                } catch {
                  completion(.failure(error))
                }
              }
            }
          }
        } catch {
          completion(.failure(error))
        }
      }
    }
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

  func create(_ note: Note, token: String?, completion: @escaping (Result<Note>) -> Void) {
    guard let token = token else {
      completion(self.createLocally(note, isSynced: false))
      return
    }

    self.networkClient.create(note, token: token) { [unowned self] createNoteResult in
      switch createNoteResult {
      case .failure:
        completion(self.createLocally(note, isSynced: false))
      case .success(let noteWithRemoteID):
        guard let jpegData = note.image?.jpegData else {
          completion(self.createLocally(noteWithRemoteID, isSynced: true))
          return
        }

        self.networkClient.uploadImage(with: jpegData, for: noteWithRemoteID, token: token) { uploadImageResult in
          switch uploadImageResult {
          case .failure:
            completion(self.createLocally(noteWithRemoteID, isSynced: false))
          case .success:
            completion(self.createLocally(noteWithRemoteID, isSynced: true))
          }
        }
      }
    }
  }

  func update(_ note: Note, token: String?, completion: @escaping (Result<Note>) -> Void) {
    guard let token = token else {
      completion(self.updateLocally(note, isSynced: false))
      return
    }

    self.networkClient.update(note, token: token) { [unowned self] result in
      switch result {
      case .failure:
        completion(self.updateLocally(note, isSynced: false))
      case .success(let noteWithRemoteID):
        guard let jpegData = note.image?.jpegData else {
          completion(self.updateLocally(noteWithRemoteID, isSynced: true))
          return
        }

        self.networkClient.uploadImage(with: jpegData, for: noteWithRemoteID, token: token) { uploadImageResult in
          switch uploadImageResult {
          case .failure:
            completion(self.updateLocally(noteWithRemoteID, isSynced: false))
          case .success:
            completion(self.updateLocally(noteWithRemoteID, isSynced: true))
          }
        }
      }
    }
  }

  func deleteAllNotes(token: String, completion: @escaping (Result<Void>) -> Void) {
    self.networkClient.deleteAllNotes(token: token) { [unowned self] result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success:
        completion(self.tryToDeleteAllNotes())
      }
    }
  }

  func image(with url: URL,
             for note: Note,
             completion: @escaping (Result<Data>) -> Void) {
    self.networkClient.image(with: url) { [unowned self] result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let jpegData):
        completion(.success(jpegData))

        var updatedNote = note
        updatedNote.image?.jpegData = jpegData
        _ = self.tryToUpdateNote(updatedNote)
      }
    }
  }

  func resetSyncState() {
    self.userPreferencesStorage.lastNotesSyncDate = nil
  }

  func isValid(note: Note) -> Bool {
    if let title = note.title, !title.isEmpty { return true }
    if note.image != nil { return true }
    if let content = note.content, !content.isEmpty { return true }
    return false
  }

  // MARK: - Helpers

  private func createLocally(_ note: Note, isSynced: Bool) -> Result<Note> {
    var noteWithCorrectSyncStatus = note
    noteWithCorrectSyncStatus.isSynced = isSynced
    return self.tryToCreateNote(noteWithCorrectSyncStatus)
  }

  private func updateLocally(_ note: Note, isSynced: Bool) -> Result<Note> {
    var noteWithCorrectSyncStatus = note
    noteWithCorrectSyncStatus.isSynced = isSynced
    return self.tryToUpdateNote(noteWithCorrectSyncStatus)
  }

  private func tryToFetchNotes() -> Result<[Note]> {
    do {
      let localNotes = try self.fetchNotes(for: "")
      return .success(localNotes)
    } catch {
      return .failure(error)
    }
  }

  private func tryToCreateNote(_ note: Note) -> Result<Note> {
    do {
      let savedNote = try self.notesStorage.create(note)
      return .success(savedNote)
    } catch {
      return .failure(error)
    }
  }

  private func tryToUpdateNote(_ note: Note) -> Result<Note> {
    do {
      let savedNote = try self.notesStorage.update(note)
      return .success(savedNote)
    } catch {
      return .failure(error)
    }
  }

  private func tryToDeleteNote(_ note: Note) -> Result<Void> {
    do {
      _ = try self.notesStorage.delete(note)
      return .success(())
    } catch {
      assertionFailure("Couldn't delete not from the local DB")
      return .failure(error)
    }
  }

  private func tryToDeleteAllNotes() -> Result<Void> {
    do {
      try self.notesStorage.deleteAllNotes()
      return .success(())
    } catch {
      assertionFailure("Couldn't deletes not from the local DB")
      return .failure(error)
    }
  }

  private func updateOrDeleteOutdatedNotes(_ notes: [Note],
                                           token: String,
                                           completion: @escaping () -> Void) {
    let dispatchGroup = DispatchGroup()

    for note in notes {
      dispatchGroup.enter()

      if note.toBeDeleted {
        self.networkClient.delete(note, token: token) { [unowned self] result in
          switch result {
          case .failure:
            // If we locally delete a note which wasn't deleted remotely it will stay on the server forever.
            // So we keep it to try to delete it remotely the next time.
            break
          case .success:
            _ = self.tryToDeleteNote(note)
          }

          dispatchGroup.leave()
        }
      } else {
        self.networkClient.update(note, token: token) { [unowned self] result in
          switch result {
          case .failure:
            break
          case .success(let noteWithRemoteID):
            guard let jpegData = noteWithRemoteID.image?.jpegData else { return }
            self.networkClient.uploadImage(with: jpegData,
                                           for: noteWithRemoteID,
                                           token: token) { uploadImageResult in
              switch uploadImageResult {
              case .failure:
                _ = self.updateLocally(noteWithRemoteID, isSynced: false)
              case .success:
                _ = self.updateLocally(noteWithRemoteID, isSynced: true)
              }
            }
          }

          dispatchGroup.leave()
        }
      }
    }

    dispatchGroup.notify(queue: .main, execute: completion)
  }
}
