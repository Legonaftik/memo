import CoreData
import CoreML
import NaturalLanguage

final class AppFactory {

    // MARK: - Singleton

    static let shared = AppFactory()
    private init() {}

    // MARK: - Public

    lazy var noteStorage: INoteStorage = coreDataNoteStorage
    let noteValidator = NoteValidator()
    let moodPredictor: MoodPredictor? = {
        do {
            // TODO: Pass an actual MLModel
            let model = try NLModel(mlModel: MLModel())
            return MoodPredictor(model: model)
        } catch {
            return nil
        }
    }()

    // MARK: - Private

    private lazy var coreDataNoteStorage = CoreDataNoteStorage(persistentContainer: persistentContainer)

    private let persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "memo")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        return container
    }()
}
