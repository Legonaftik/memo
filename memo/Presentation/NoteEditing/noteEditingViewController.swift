//
//  NoteEditingViewController.swift
//  memo
//
//  Created by Vladimir Pavlov on 10/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class NoteEditingViewController: UIViewController {

  var notesService: IAuthorizedNoteServiceFacade!

  var noteLocalID: UUID? // If not set then we're in creating mode (not editing)
  private var existingNote: Note? {
    didSet {
      if let existingNote = self.existingNote {
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
    self.dismiss(animated: true)
  }

  @IBAction private func done(_ sender: UIBarButtonItem) {
    if let existingNote = self.existingNote {
      self.editNote(existingNote)
    } else {
      self.createNewNote()
    }
  }

  @IBAction private func selectPhoto(_ sender: UITapGestureRecognizer) {
    self.presentPhotoSelectionActionSheet()
  }

  @IBAction private func titleDidChange() {
    self.updateDoneButtonAvailability()
  }

  // MARK: - View Controller lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    self.hideKeyboardWhenTappedAround()
    self.addObserversForKeyboardAppearance()

    if let noteLocalID = self.noteLocalID {
      self.getNote(with: noteLocalID)
      self.contentTextView.textColor = .black
    } else {
      self.dateLabel.text = dateFormatter.string(from: Date())
      self.contentTextView.textColor = .lightGray
    }
    self.contentLengthLeftLabel.text = String(self.maximumContentLength - self.contentTextView.text.count)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let datePickerSegue = R.segue.noteEditingViewController.datePicker(segue: segue) {
      let datePickerViewController = datePickerSegue.destination.topViewController as! DatePickerViewController
      datePickerViewController.delegate = self
    }
  }

  // MARK: - Complete creation/editing

  private func editNote(_ note: Note) {
    let image: MemoImage?
    if self.photoImageView.image!.isEqual(R.image.photoPlaceholder()) {
      image = nil
    } else {
      let jpegData = self.photoImageView.image!.jpegData(compressionQuality: 1)!
      image = MemoImage(jpegData: jpegData, remoteURL: nil)
    }

    let updatedNote = Note(localID: note.localID, remoteID: note.remoteID, content: self.contentTextView.text,
                           creationDate: dateFormatter.date(from: self.dateLabel.text!) ?? Date(),
                           image: image, mood: UInt8(self.moodControl.selectedSegmentIndex),
                           title: self.titleLabel.text, isSynced: false, toBeDeleted: false)

    self.cancelButton.isEnabled = false
    self.doneButton.isEnabled = false
    self.notesService.update(updatedNote) { [weak self] updateResult in
      guard let self = self else { return }

      DispatchQueue.main.async {
        switch updateResult {
        case .failure(let error):
          self.displayAlert(message: error.localizedDescription)
        case .success:
          self.dismiss(animated: true)
        }

        self.cancelButton.isEnabled = true
        self.doneButton.isEnabled = true
      }
    }
  }

  private func createNewNote() {
    self.cancelButton.isEnabled = false
    self.doneButton.isEnabled = false
    self.notesService.create(self.makeNoteFromUIState()) { [weak self] createResult in
      guard let self = self else { return }

      DispatchQueue.main.async {
        switch createResult {
        case .failure(let error):
          self.displayAlert(message: error.localizedDescription)
        case .success:
          self.dismiss(animated: true)
        }

        self.cancelButton.isEnabled = true
        self.doneButton.isEnabled = true
      }
    }
  }

  // MARK: - Helpers

  private func getNote(with localID: UUID) {
    self.doneButton.isEnabled = false
    do {
      self.existingNote = try self.notesService.note(with: localID)
    } catch {
      self.displayAlert(message: error.localizedDescription)
    }
    self.doneButton.isEnabled = true
  }

  private func setupUIForNote(_ note: Note) {
    self.dateLabel.text = dateFormatter.string(from: note.creationDate)
    self.titleLabel.text = note.title
    self.contentTextView.text = note.content
    self.moodControl.selectedSegmentIndex = Int(note.mood)
    if let jpegData = note.image?.jpegData {
      self.photoImageView.image = UIImage(data: jpegData)
    }
  }

  private func presentPhotoSelectionActionSheet() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

    let galeryAction = UIAlertAction(title: R.string.localizable.chooseFromGallery(),
                                     style: .default) { [unowned self] _ in
      self.imagePickerController.sourceType = .photoLibrary
      self.present(self.imagePickerController, animated: true)
      self.imagePickerController.delegate = self
    }

    let cameraAction = UIAlertAction(title: R.string.localizable.takeAPhoto(),
                                     style: .default) { [unowned self] _ in
      self.imagePickerController.sourceType = .camera
      self.present(self.imagePickerController, animated: true)
      self.imagePickerController.delegate = self
    }

    let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)

    alertController.addAction(galeryAction)
    alertController.addAction(cameraAction)
    alertController.addAction(cancelAction)

    self.present(alertController, animated: true)
  }

  private func makeNoteFromUIState() -> Note {
    let content: String?
    if !self.contentTextView.text.isEmpty && self.contentTextView.text != R.string.localizable.howAreYou() {
      content = self.contentTextView.text
    } else {
      content = nil
    }

    let image: MemoImage?
    if self.photoImageView.image!.isEqual(R.image.photoPlaceholder()) {
      image = nil
    } else {
      let jpegData = self.photoImageView.image!.jpegData(compressionQuality: 1)!
      image = MemoImage(jpegData: jpegData, remoteURL: nil)
    }

    return Note(localID: UUID(), remoteID: nil, content: content,
                creationDate: dateFormatter.date(from: dateLabel.text!) ?? Date(),
                image: image, mood: UInt8(self.moodControl.selectedSegmentIndex),
                title: self.titleLabel.text, isSynced: false, toBeDeleted: false)
  }

  private func updateDoneButtonAvailability() {
    self.doneButton.isEnabled = self.notesService.isValid(note: self.makeNoteFromUIState())
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
      return string.count <= self.maximumTitleLength
    }
    return textFieldText.count + string.count <= self.maximumTitleLength
  }
}

extension NoteEditingViewController: UITextViewDelegate {

  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.text == R.string.localizable.howAreYou() {
      textView.text = ""
      textView.textColor = .black
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.isEmpty {
      textView.text = R.string.localizable.howAreYou()
      textView.textColor = .lightGray
    }
    self.updateDoneButtonAvailability()
  }

  func textViewDidChange(_ textView: UITextView) {
    self.contentLengthLeftLabel.text = String(self.maximumContentLength - textView.text.count)
    self.updateDoneButtonAvailability()
  }

  func textView(_ textView: UITextView,
                shouldChangeTextIn range: NSRange,
                replacementText text: String) -> Bool {
    return textView.text.count + text.count <= self.maximumContentLength
  }
}

extension NoteEditingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    if let image = info[.originalImage] as? UIImage {
      self.photoImageView.image = image
    }
    self.updateDoneButtonAvailability()
    self.dismiss(animated: true)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    self.updateDoneButtonAvailability()
    self.dismiss(animated: true)
  }
}

extension NoteEditingViewController: DatePickerViewControllerDelegate {

  func datePicker(_ datePicker: DatePickerViewController, didSelect date: Date) {
    self.dateLabel.text = dateFormatter.string(from: date)
  }
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.locale = .current
  formatter.timeStyle = .short
  formatter.dateStyle = .short
  return formatter
}()
