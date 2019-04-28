//
//  AppFactory.swift
//  Diary
//
//  Created by Vladimir Pavlov on 11/03/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import CoreData

final class AppFactory {

  // MARK: - Singleton

  static let factory = AppFactory()
  private init() {}

  // MARK: - Services

  func makeAuthService() -> IAuthService {
    return FirebaseAuthService()
  }

  func makeAuthorizedNotesService() -> IAuthorizedNoteServiceFacade {
    return AuthorizedNoteServiceFacade(authService: self.makeAuthService(),
                                       notesService: self.makeNotesService())
  }

  func makeNotesService() -> INoteService {
    return NoteService(networkClient: self.networkClient,
                       notesStorage: self.coreDataStorage,
                       userPreferencesStorage: self.userPreferencesStorage)
  }

  // MARK: - Core Components

  private lazy var networkClient: INetworkClient = NetworkClient()
  private lazy var coreDataStorage: INotesStorage = CoreDataNotesStorage(persistentContainer: self.persistentContainer)
  private lazy var userPreferencesStorage: IUserPreferencesStorage = UserPreferencesStorage()

  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "Diary")
    container.loadPersistentStores { _, error in
      if let error = error {
        fatalError("Unable to load persistent stores: \(error)")
      }
    }
    return container
  }()
}
