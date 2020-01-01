//
//  Created by Vladimir Pavlov on 18/06/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

final class SettingsViewController: UITableViewController {

    // MARK: - Private

    private let noteStorage = AppFactory.shared.noteStorage

    @IBAction private func deleteAllNotes(_ sender: UIButton) {
        sender.isEnabled = false
        defer {
            sender.isEnabled = true
        }

        let alertMessage: String
        do {
            try noteStorage.deleteAllNotes()
            alertMessage = R.string.localizable.allTheNotesWereDeleted()
        } catch {
            alertMessage = error.localizedDescription
        }

        displayAlert(message: alertMessage)
    }

    @IBAction private func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
