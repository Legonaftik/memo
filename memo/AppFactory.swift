//
//  Created by Vladimir Pavlov on 11/03/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import CoreData
import NaturalLanguage
import CoreML

final class AppFactory {

    // MARK: - Singleton

    static let shared = AppFactory()
    private init() {}

    // MARK: - Public

    lazy var noteStorage: INoteStorage = coreDataNoteStorage
    lazy var noteValidator = NoteValidator()
    lazy var moodPredictor: MoodPredictor? = {
        do {
            // TODO: Pass a real MLModel
            let model = try NLModel(mlModel: MLModel())
            return MoodPredictor(model: model)
        } catch {
            return nil
        }
    }()

    // MARK: - Private

    private lazy var coreDataNoteStorage = CoreDataNoteStorage(persistentContainer: persistentContainer)

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
