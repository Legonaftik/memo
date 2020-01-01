//
//  AppFactory.swift
//  memo
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

  func makeNotesService() -> INoteService {
    return NoteService(notesStorage: self.coreDataStorage)
  }

  // MARK: - Core Components

  private lazy var coreDataStorage = CoreDataNotesStorage(persistentContainer: self.persistentContainer)

  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "memo")
    container.loadPersistentStores { _, error in
      if let error = error {
        fatalError("Unable to load persistent stores: \(error)")
      }
    }
    return container
  }()
}
