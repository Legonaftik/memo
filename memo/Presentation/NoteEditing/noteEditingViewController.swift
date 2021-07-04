import UIKit

final class NoteEditingViewController: UIViewController {

    var onNoteUpdate: () -> Void = {}

    var noteStorage: INoteStorage!
    var noteValidator: NoteValidator!
    private let moodPredictor = AppFactory.shared.moodPredictor

    var noteLocalID: UUID? // If not set then we're in creating mode (not editing)
    private var existingNote: Note? {
        didSet {
            if let existingNote = existingNote {
                self.setupUIForNote(existingNote)
            }
        }
    }

    private lazy var imagePickerController = UIImagePickerController()

    private let maximumTitleLength = 100
    private let maximumContentLength = 10_000

    @IBOutlet private var photoImageView: UIImageView!
    @IBOutlet private var cancelButton: UIBarButtonItem!
    @IBOutlet private var doneButton: UIBarButtonItem!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var titleLabel: UITextField!
    @IBOutlet private var contentTextView: UITextView!
    @IBOutlet private var contentLengthLeftLabel: UILabel!
    @IBOutlet private var moodControl: MoodControl!

    @IBAction private func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction private func done(_ sender: UIBarButtonItem) {
        if let existingNote = existingNote {
            editNote(existingNote)
        } else {
            createNewNote()
        }
    }

    @IBAction private func selectPhoto(_ sender: UITapGestureRecognizer) {
        presentPhotoSelectionActionSheet()
    }

    @IBAction private func titleDidChange() {
        updateDoneButtonAvailability()
    }

    // MARK: - View Controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround()
        addObserversForKeyboardAppearance()

        if let noteLocalID = noteLocalID {
            getNote(with: noteLocalID)
            contentTextView.textColor = .label
        } else {
            dateLabel.text = dateFormatter.string(from: Date())
            contentTextView.textColor = .secondaryLabel
        }
        contentLengthLeftLabel.text = String(maximumContentLength - contentTextView.text.count)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let datePickerSegue = R.segue.noteEditingViewController.datePicker(segue: segue) {
            let datePickerViewController = datePickerSegue.destination.topViewController as! DatePickerViewController
            datePickerViewController.delegate = self
        }
    }

    // MARK: - Complete creation/editing

    private func editNote(_ note: Note) {
        cancelButton.isEnabled = false
        doneButton.isEnabled = false
        defer {
            cancelButton.isEnabled = true
            doneButton.isEnabled = true
        }

        let image: MemoImage?
        if photoImageView.image == nil || photoImageView.image?.pngData() == R.image.photoPlaceholder()?.pngData() {
            image = nil
        } else if let jpegData = photoImageView.image?.jpegData(compressionQuality: 1) {
            image = MemoImage(jpegData: jpegData)
        } else {
            image = nil
        }

        let updatedNote = Note(
            localID: note.localID,
            content: contentTextView.text,
            creationDate: generateCreationDate(makeNowIfRecent: false),
            image: image,
            mood: UInt8(moodControl.selectedSegmentIndex),
            title: titleLabel.text
        )

        do {
            _ = try noteStorage.update(updatedNote)
            onNoteUpdate()
            dismiss(animated: true)
        } catch {
            displayAlert(message: error.localizedDescription)
        }
    }

    private func createNewNote() {
        cancelButton.isEnabled = false
        doneButton.isEnabled = false
        defer {
            cancelButton.isEnabled = true
            doneButton.isEnabled = true
        }

        do {
            _ = try noteStorage.create(makeNoteFromUIState())
            onNoteUpdate()
            dismiss(animated: true)
        } catch {
            displayAlert(message: error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func getNote(with localID: UUID) {
        doneButton.isEnabled = false
        do {
            existingNote = try noteStorage.note(with: localID)
        } catch {
            displayAlert(message: error.localizedDescription)
        }
        doneButton.isEnabled = true
    }

    private func setupUIForNote(_ note: Note) {
        dateLabel.text = dateFormatter.string(from: note.creationDate)
        titleLabel.text = note.title
        contentTextView.text = note.content
        moodControl.selectedSegmentIndex = Int(note.mood)
        if let jpegData = note.image?.jpegData {
            photoImageView.image = UIImage(data: jpegData)
        } else {
            photoImageView.image = R.image.photoPlaceholder()
        }
    }

    private func presentPhotoSelectionActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoLibrary = UIAlertAction(
                title: R.string.localizable.chooseFromPhotoLibrary(),
                style: .default,
                handler: { [unowned self] _ in
                    imagePickerController.sourceType = .photoLibrary
                    present(imagePickerController, animated: true)
                    imagePickerController.delegate = self
                }
            )
            alertController.addAction(photoLibrary)
        }

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(
                title: R.string.localizable.takeAPhoto(),
                style: .default,
                handler: { [unowned self] _ in
                    imagePickerController.sourceType = .camera
                    present(imagePickerController, animated: true)
                    imagePickerController.delegate = self
                }
            )
            alertController.addAction(cameraAction)
        }

        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    private func makeNoteFromUIState() -> Note {
        let content: String?
        if !contentTextView.text.isEmpty && contentTextView.text != R.string.localizable.howAreYou() {
            content = contentTextView.text
        } else {
            content = nil
        }

        let image: MemoImage?
        if photoImageView.image == nil || photoImageView.image?.pngData() == R.image.photoPlaceholder()?.pngData() {
            image = nil
        } else if let jpegData = photoImageView.image?.jpegData(compressionQuality: 1) {
            image = MemoImage(jpegData: jpegData)
        } else {
            image = nil
        }

        return Note(
            localID: UUID(),
            content: content,
            creationDate: generateCreationDate(makeNowIfRecent: true),
            image: image,
            mood: UInt8(moodControl.selectedSegmentIndex),
            title: titleLabel.text
        )
    }

    private func updateDoneButtonAvailability() {
        doneButton.isEnabled = noteValidator.isValid(note: makeNoteFromUIState())
    }

    private func updatePredictedMood() {
        if let moodPredictor = moodPredictor {
            let predictedMood = moodPredictor.mood(text: contentTextView.text)
            moodControl.selectedSegmentIndex = Int(predictedMood)
        }
    }

    private func generateCreationDate(makeNowIfRecent: Bool) -> Date {
        let maxTimeToCreateNote: TimeInterval = 120
        if let text = dateLabel.text, let date = dateFormatter.date(from: text) {
            if makeNowIfRecent && date.distance(to: Date()) < maxTimeToCreateNote {
                return Date()
            } else {
                return date
            }
        } else {
            return Date()
        }
    }
}

extension NoteEditingViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let textFieldText = textField.text else {
            return string.count <= maximumTitleLength
        }
        return textFieldText.count + string.count <= maximumTitleLength
    }
}

extension NoteEditingViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == R.string.localizable.howAreYou() {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = R.string.localizable.howAreYou()
            textView.textColor = .placeholderText
        }
        updateDoneButtonAvailability()
        updatePredictedMood()
    }

    func textViewDidChange(_ textView: UITextView) {
        contentLengthLeftLabel.text = String(maximumContentLength - textView.text.count)
        updateDoneButtonAvailability()
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        return textView.text.count + text.count <= maximumContentLength
    }
}

extension NoteEditingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let image = info[.originalImage] as? UIImage {
            photoImageView.image = image
        }
        updateDoneButtonAvailability()
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        updateDoneButtonAvailability()
        dismiss(animated: true)
    }
}

extension NoteEditingViewController: DatePickerViewControllerDelegate {

    func datePicker(_ datePicker: DatePickerViewController, didSelect date: Date) {
        dateLabel.text = dateFormatter.string(from: date)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    return formatter
}()
