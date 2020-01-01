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

    static let shared = AppFactory()
    private init() {}

    // MARK: - Services

    func makeNotesService() -> INoteService {
        return NoteService(notesStorage: coreDataStorage)
    }

    // MARK: - Core Components

    private lazy var coreDataStorage = CoreDataNotesStorage(persistentContainer: persistentContainer)

    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "memo")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        return container
    }()
}
