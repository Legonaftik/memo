import UIKit

final class NoteDetailsViewController: UIViewController {

    var noteStorage: INoteStorage!
    var noteID: UUID!
    private var note: Note? {
        didSet {
            if let note = note {
                setupUI(with: note)
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter
    }()

    // MARK: - Interface Builder

    @IBOutlet private var photoImageView: UIImageView!
    @IBOutlet private var editBarButtonItem: UIBarButtonItem!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var titleLabel: UITextField!
    @IBOutlet private var contentTextView: UITextView!
    @IBOutlet private var moodControl: MoodControl!

    // MARK: - View Controller lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getNote(with: noteID)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let editNoteSegue = R.segue.noteDetailsViewController.editNote(segue: segue) {
            let noteEditingVC = editNoteSegue.destination.topViewController as! NoteEditingViewController
            noteEditingVC.noteStorage = noteStorage
            noteEditingVC.noteValidator = AppFactory.shared.noteValidator
            noteEditingVC.noteLocalID = noteID
            noteEditingVC.onNoteUpdate = { [unowned self] in
                getNote(with: noteID)
            }
        }
    }

    // MARK: - Helpers

    private func getNote(with localID: UUID) {
        do {
            note = try noteStorage.note(with: noteID)
        } catch {
            displayAlert(message: error.localizedDescription)
        }
    }

    private func setupUI(with note: Note) {
        dateLabel.text = dateFormatter.string(from: note.creationDate)
        titleLabel.text = note.title
        contentTextView.text = note.content
        moodControl.selectedSegmentIndex = Int(note.mood)

        if let jpegData = note.image?.jpegData {
            photoImageView.image = UIImage(data: jpegData)
        }
    }
}
