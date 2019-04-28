//
//  SettingsViewController.swift
//  Diary
//
//  Created by Vladimir Pavlov on 18/06/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class SettingsViewController: UITableViewController {

  // MARK: - Interface

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let buttonTitle = self.authService.isLoggedIn() ? R.string.localizable.logOut() : R.string.localizable.logIn()
    self.logInOrOutButton.setTitle(buttonTitle, for: .normal)
  }

  // MARK: - Private

  private let authService: IAuthService = AppFactory.factory.makeAuthService()
  private let noteService: IAuthorizedNoteServiceFacade = AppFactory.factory.makeAuthorizedNotesService()
  private let unauthorizedNoteService: INoteService = AppFactory.factory.makeNotesService()

  @IBOutlet private var logInOrOutButton: UIButton!

  @IBAction private func syncNotes(_ sender: UIButton) {
    sender.isEnabled = false
    self.unauthorizedNoteService.resetSyncState()
    self.displayAlert(message: R.string.localizable.resetSyncDate())
    sender.isEnabled = true
  }

  @IBAction private func deleteAllNotes(_ sender: UIButton) {
    sender.isEnabled = false
    self.noteService.deleteAllNotes { [weak self] result in
      guard let self = self else { return }

      DispatchQueue.main.async {
        let alertMessage: String
        switch result {
        case .failure(let error):
          alertMessage = error.localizedDescription
        case .success:
          alertMessage = R.string.localizable.allTheNotesWereDeleted()
        }
        self.displayAlert(message: alertMessage)

        sender.isEnabled = true
      }
    }
  }

  @IBAction private func logInOrOut(_ sender: UIButton) {
    if self.authService.isLoggedIn() {
      do {
        try self.authService.signOut()
        sender.setTitle(R.string.localizable.logIn(), for: .normal)
        self.displayAlert(message: R.string.localizable.youHaveSuccessfullyLoggedOut())
      } catch {
        self.displayAlert(message: error.localizedDescription)
      }
    } else {
      let authScreen = authService.createAuthScreen()
      self.present(authScreen, animated: true)
    }
  }

  @IBAction private func done(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true)
  }
}
