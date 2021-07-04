import UIKit

protocol ContentViewController: UIViewController {
    func updateContent()
}

final class MainViewController: UIViewController {

    private enum Page: Int {
        case list
        case calendar
    }

    private let noteStorage = AppFactory.shared.noteStorage

    private lazy var notesListViewController: NotesListViewController = {
        let notesListVC = R.storyboard.main.notesListViewController()!
        notesListVC.noteStorage = noteStorage
        return notesListVC
    }()

    private lazy var calendarViewController: CalendarViewController = {
        let calendarVC = R.storyboard.main.calendarViewController()!
        calendarVC.noteStorage = noteStorage
        return calendarVC
    }()

    private var contentViewController: ContentViewController? {
        didSet {
            if let oldVC = oldValue {
                oldVC.willMove(toParent: nil)
                oldVC.view.removeFromSuperview()
                oldVC.removeFromParent()
            }
            if let newVC = contentViewController {
                self.addChild(newVC)
                self.view.addSubview(newVC.view)
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
            contentViewController = notesListViewController
        case .calendar:
            contentViewController = calendarViewController
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentViewController = notesListViewController
        notesListViewController.delegate = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let newNoteSegue = R.segue.mainViewController.newNote(segue: segue) {
            let noteEditingVC = newNoteSegue.destination.topViewController as! NoteEditingViewController
            noteEditingVC.noteStorage = noteStorage
            noteEditingVC.noteValidator = AppFactory.shared.noteValidator
            noteEditingVC.onNoteUpdate = { [unowned self] in
                contentViewController?.updateContent()
            }
        } else if let noteDetailsSegue = R.segue.mainViewController.noteDetails(segue: segue) {
            noteDetailsSegue.destination.noteStorage = noteStorage
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
