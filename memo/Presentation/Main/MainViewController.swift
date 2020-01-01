//
//  MainViewController.swift
//  memo
//
//  Created by Vladimir Pavlov on 17/03/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class MainViewController: UIViewController {

  private enum Page: Int {
    case list
    case calendar
  }

  private let noteService = AppFactory.factory.makeNotesService()

  private lazy var notesListViewController: NotesListViewController = {
    let notesListVC = R.storyboard.main.notesListViewController()!
    notesListVC.notesService = self.noteService
    return notesListVC
  }()

  private lazy var calendarViewController: CalendarViewController = {
    let calendarVC = R.storyboard.main.calendarViewController()!
    calendarVC.notesService = self.noteService
    return calendarVC
  }()

  private var containedController: UIViewController? {
    didSet {
      if let oldVC = oldValue {
        oldVC.willMove(toParent: nil)
        oldVC.view.removeFromSuperview()
        oldVC.removeFromParent()
      }
      if let newVC = containedController {
        self.addChild(newVC)
        self.view.addSubview(newVC.view)
        newVC.view.frame = self.view.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newVC.didMove(toParent: self)
      }
    }
  }

  @IBOutlet private var containerView: UIView!

  @IBAction private func changePage(_ sender: UISegmentedControl) {
    let page = Page(rawValue: sender.selectedSegmentIndex)!
    switch page {
    case .list:
      self.containedController = self.notesListViewController
    case .calendar:
      self.containedController = self.calendarViewController
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    containedController = notesListViewController
    notesListViewController.delegate = self
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let newNoteSegue = R.segue.mainViewController.newNote(segue: segue) {
      let noteEditingViewController = newNoteSegue.destination.topViewController as! NoteEditingViewController
      noteEditingViewController.notesService = self.noteService
      return
    }

    if let noteDetailsSegue = R.segue.mainViewController.noteDetails(segue: segue) {
      noteDetailsSegue.destination.notesService = self.noteService
      noteDetailsSegue.destination.noteID = (sender as! UUID)
    }
  }
}

extension MainViewController: NotesListViewControllerDelegate {

  func notesListViewController(
    _ notesListVC: NotesListViewController,
    didSelectNoteWith localID: UUID
  ) {
    performSegue(withIdentifier: R.segue.mainViewController.noteDetails, sender: localID)
  }
}
