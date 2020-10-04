import UIKit

protocol NotesListViewControllerDelegate: AnyObject {
    func notesListViewController(_ notesListVC: NotesListViewController, didSelectNoteWith localID: UUID)
    func notesListViewController(_ notesListVC: NotesListViewController, didUpdate contentHeight: CGFloat)
}

extension NotesListViewControllerDelegate {
    func notesListViewController(_ notesListVC: NotesListViewController, didSelectNoteWith localID: UUID) {}
    func notesListViewController(_ notesListVC: NotesListViewController, didUpdate contentHeight: CGFloat) {}
}

final class NotesListViewController: UITableViewController {

    weak var delegate: NotesListViewControllerDelegate?
    var noteStorage: INoteStorage!

    var dateToDisplay: Date? {
        didSet {
            if let dateToDisplay = dateToDisplay {
                showOnlyNotesOfDateDay(dateToDisplay)
            }
        }
    }

    private var notes: [Note] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private let searchController = UISearchController(searchResultsController: nil)

    // This property is used to notify a delegate only when content height actually changes
    private var savedTableContenHeight: CGFloat = 0

    // MARK: - View controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateNotesList()
        // Avoid the state when both navigation bar and search controller are visible
        navigationController?.isNavigationBarHidden = searchController.isActive
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Otherwise navigation controller will be hidden for the next VC
        navigationController?.isNavigationBarHidden = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        notifyDelegateAboutNewContentHeightAndSaveIt()
    }

    // MARK: - Helpers

    private func updateNotesList() {
        fetchNotes(for: "")
    }

    private func fetchNotes(for searchQuery: String) {
        do {
            notes = try noteStorage.notes(for: searchQuery)
        } catch {
            displayAlert(message: error.localizedDescription)
        }
    }

    private func showOnlyNotesOfDateDay(_ date: Date) {
        do {
            notes = try noteStorage.notes(for: date)
        } catch {
            displayAlert(message: error.localizedDescription)
        }
    }

    private func notifyDelegateAboutNewContentHeightAndSaveIt() {
        let newContentHeight = tableView.contentSize.height
        if newContentHeight != savedTableContenHeight {
            delegate?.notesListViewController(self, didUpdate: newContentHeight)
            savedTableContenHeight = newContentHeight
        }
    }

    private func setupSearchController() {
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
    }

    private func setImage(for note: Note, in cell: NoteTableViewCell) {
        if let jpegData = note.image?.jpegData {
            cell.setImage(with: jpegData)
        }
    }

    // MARK: - UITableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    // swiftlint:disable:next function_body_length
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = notes[indexPath.row]

        // REFACTOR: Yeah, it's sad...
        if let title = note.title, !title.isEmpty, note.image != nil, let content = note.content, !content.isEmpty {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.noteTitleImageContent,
                for: indexPath)!
            cell.configure(with: note)
            setImage(for: note, in: cell)
            return cell
        } else if let title = note.title, !title.isEmpty, note.image != nil {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.noteTitleImage,
                for: indexPath)!
            cell.configure(with: note)
            setImage(for: note, in: cell)
            return cell
        } else if let title = note.title, !title.isEmpty, let content = note.content, !content.isEmpty {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.noteTitleContent,
                for: indexPath)!
            cell.configure(with: note)
            setImage(for: note, in: cell)
            return cell
        } else if note.image != nil, let content = note.content, !content.isEmpty {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.noteImageContent,
                for: indexPath)!
            cell.configure(with: note)
            setImage(for: note, in: cell)
            return cell
        } else if let title = note.title, !title.isEmpty {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.noteTitle,
                for: indexPath)!
            cell.configure(with: note)
            setImage(for: note, in: cell)
            return cell
        } else if note.image != nil {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.noteImage,
                for: indexPath)!
            cell.configure(with: note)
            setImage(for: note, in: cell)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.noteContent,
                for: indexPath)!
            cell.configure(with: note)
            setImage(for: note, in: cell)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.notesListViewController(self, didSelectNoteWith: notes[indexPath.row].localID)
    }
}

extension NotesListViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        fetchNotes(for: searchBar.text!)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateNotesList()
    }
}
