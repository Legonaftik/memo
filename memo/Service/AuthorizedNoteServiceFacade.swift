//
//  AuthorizedNoteServiceFacade.swift
//  memo
//
//  Created by Vladimir Pavlov on 13/05/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

protocol IAuthorizedNoteServiceFacade {

  func syncNotes(completion: @escaping (Result<Void>) -> Void)
  func fetchNotes(for searchQuery: String) throws -> [Note]
  func fetchNotes(for date: Date) throws -> [Note]
  func dailyNotesInfo() throws -> [Date: (UInt, UInt)]
  func note(with localID: UUID) throws -> Note
  func create(_ note: Note, completion: @escaping (Result<Note>) -> Void)
  func update(_ note: Note, completion: @escaping (Result<Note>) -> Void)
  func deleteAllNotes(completion: @escaping (Result<Void>) -> Void)
  func image(with url: URL,
             for note: Note,
             completion: @escaping (Result<Data>) -> Void)

  func isValid(note: Note) -> Bool
}

final class AuthorizedNoteServiceFacade: IAuthorizedNoteServiceFacade {

  private let authService: IAuthService
  private let notesService: INoteService

  init(authService: IAuthService, notesService: INoteService) {
    self.authService = authService
    self.notesService = notesService
  }

  func syncNotes(completion: @escaping (Result<Void>) -> Void) {
    self.authService.updateAccessToken { [unowned self] updateAccessTokenResult in
      switch updateAccessTokenResult {
      case .failure(let error):
        completion(.failure(error))
      case .success(let token):
        self.notesService.syncNotes(token: token, completion: completion)
      }
    }
  }

  func fetchNotes(for searchQuery: String) throws -> [Note] {
    return try self.notesService.fetchNotes(for: searchQuery)
  }

  func fetchNotes(for date: Date) throws -> [Note] {
    return try self.notesService.fetchNotes(for: date)
  }

  func dailyNotesInfo() throws -> [Date: (UInt, UInt)] {
    return try self.notesService.dailyNotesInfo()
  }

  func note(with localID: UUID) throws -> Note {
    return try self.notesService.note(with: localID)
  }

  func create(_ note: Note, completion: @escaping (Result<Note>) -> Void) {
    self.authService.updateAccessToken { [unowned self] updateAccessTokenResult in
      switch updateAccessTokenResult {
      case .failure:
        self.notesService.create(note, token: nil, completion: completion)
      case .success(let token):
        self.notesService.create(note, token: token, completion: completion)
      }
    }
  }

  func update(_ note: Note, completion: @escaping (Result<Note>) -> Void) {
    self.authService.updateAccessToken { [unowned self] updateAccessTokenResult in
      switch updateAccessTokenResult {
      case .failure:
        self.notesService.update(note, token: nil, completion: completion)
      case .success(let token):
        self.notesService.update(note, token: token, completion: completion)
      }
    }
  }

  func deleteAllNotes(completion: @escaping (Result<Void>) -> Void) {
    self.authService.updateAccessToken { [unowned self] updateTokenResult in
      switch updateTokenResult {
      case .failure(let error):
        completion(.failure(error))
      case .success(let token):
        self.notesService.deleteAllNotes(token: token, completion: completion)
      }
    }
  }

  func image(with url: URL,
             for note: Note,
             completion: @escaping (Result<Data>) -> Void) {
    self.notesService.image(with: url, for: note, completion: completion)
  }

  func isValid(note: Note) -> Bool {
    return self.notesService.isValid(note: note)
  }
}
