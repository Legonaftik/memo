//
//  SettingsViewController.swift
//  memo
//
//  Created by Vladimir Pavlov on 18/06/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class SettingsViewController: UITableViewController {

  // MARK: - Private

  private let unauthorizedNoteService: INoteService = AppFactory.factory.makeNotesService()

  @IBAction private func deleteAllNotes(_ sender: UIButton) {
    sender.isEnabled = false

    unauthorizedNoteService.deleteAllNotes { [weak self] result in
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

  @IBAction private func done(_ sender: UIBarButtonItem) {
    dismiss(animated: true)
  }
}
