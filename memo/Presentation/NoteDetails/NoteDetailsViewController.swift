//
//  NoteDetailsViewController.swift
//  memo
//
//  Created by Vladimir Pavlov on 17/03/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class NoteDetailsViewController: UIViewController {

  var notesService: IAuthorizedNoteServiceFacade!
  var noteID: UUID!
  private var note: Note? {
    didSet {
      if let note = self.note {
        self.setupUI(with: note)
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
    self.getNote(with: self.noteID)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let editNoteSegue = R.segue.noteDetailsViewController.editNote(segue: segue) {
      let noteEditingViewController = editNoteSegue.destination.topViewController as! NoteEditingViewController
      noteEditingViewController.notesService = self.notesService
      noteEditingViewController.noteLocalID = self.noteID
    }
  }

  // MARK: - Helpers

  private func getNote(with localID: UUID) {
    do {
      self.note = try self.notesService.note(with: self.noteID)
    } catch {
      self.displayAlert(message: error.localizedDescription)
    }
  }

  private func setupUI(with note: Note) {
    self.dateLabel.text = self.dateFormatter.string(from: note.creationDate)
    self.titleLabel.text = note.title
    self.contentTextView.text = note.content
    self.moodControl.selectedSegmentIndex = Int(note.mood)

    if let jpegData = note.image?.jpegData {
      self.photoImageView.image = UIImage(data: jpegData)
    }
  }
}
