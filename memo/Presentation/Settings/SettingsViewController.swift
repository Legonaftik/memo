import UIKit

final class SettingsViewController: UITableViewController {

    var onNotesDeletion: () -> Void = {}

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
            onNotesDeletion()
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
