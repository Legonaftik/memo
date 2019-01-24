//
//  MainViewController.swift
//  Diary
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

  private let authService: IAuthService = AppFactory.factory.makeAuthService()
  private let noteService: IAuthorizedNoteServiceFacade = AppFactory.factory.makeAuthorizedNotesService()

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
        addChild(newVC)
        view.addSubview(newVC.view)
        newVC.view.frame = view.bounds
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
      containedController = notesListViewController
    case .calendar:
      containedController = calendarViewController
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    containedController = notesListViewController
    notesListViewController.delegate = self

    if !authService.isLoggedIn() {
      present(authService.createAuthScreen(), animated: true)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let newNoteSegue = R.segue.mainViewController.newNote(segue: segue) {
      let noteEditingViewController = newNoteSegue.destination.topViewController as! NoteEditingViewController
      noteEditingViewController.notesService = noteService
      return
    }

    if let noteDetailsSegue = R.segue.mainViewController.noteDetails(segue: segue) {
      noteDetailsSegue.destination.notesService = noteService
      noteDetailsSegue.destination.noteID = (sender as! UUID)
    }
  }

  private func signOut() {
    do {
      try authService.signOut()
      displayAlert(message: R.string.localizable.youHaveSuccessfullyLoggedOut())
    } catch {
      displayAlert(message: error.localizedDescription)
    }
  }
}

extension MainViewController: NotesListViewControllerDelegate {

  func notesListViewController(_ notesListVC: NotesListViewController, didSelectNoteWith localID: UUID) {
    performSegue(withIdentifier: R.segue.mainViewController.noteDetails, sender: localID)
  }
}
