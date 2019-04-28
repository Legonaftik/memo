//
//  NotesListViewController.swift
//  Diary
//
//  Created by Vladimir Pavlov on 04/10/2017.
//  Copyright © 2017 Vladimir Pavlov. All rights reserved.
//

import UIKit

@objc protocol NotesListViewControllerDelegate: class {
  @objc optional func notesListViewController(_ notesListVC: NotesListViewController,
                                              didSelectNoteWith localID: UUID)
  @objc optional func notesListViewController(_ notesListVC: NotesListViewController,
                                              didUpdate contentHeight: CGFloat)
}

final class NotesListViewController: UITableViewController {

  weak var delegate: NotesListViewControllerDelegate?
  var notesService: IAuthorizedNoteServiceFacade!

  var dateToDisplay: Date? {
    didSet {
      if let dateToDisplay = self.dateToDisplay {
        self.showOnlyNotesOfDateDay(dateToDisplay)
      }
    }
  }

  private var notes: [Note] = [] {
    didSet {
      self.tableView.reloadData()
    }
  }

  private let searchController = UISearchController(searchResultsController: nil)

  // This property is used to notify a delegate only when content height actually changes
  private var savedTableContenHeight: CGFloat = 0

  // MARK: - View controller lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupSearchController()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateNotesList()
    // Avoid the state when both navigation bar and search controller are visible
    self.navigationController?.isNavigationBarHidden = self.searchController.isActive
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // Otherwise navigation controller will be hidden for the next VC
    self.navigationController?.isNavigationBarHidden = false
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    self.notifyDelegateAboutNewContentHeightAndSaveIt()
  }

  // MARK: - Helpers

  private func updateNotesList() {
    self.fetchNotes(for: "")

    self.notesService.syncNotes { updateNotesResult in
      switch updateNotesResult {
      case .success:
        DispatchQueue.main.async { self.fetchNotes(for: "") }
      case .failure:
        break
      }
    }
  }

  private func fetchNotes(for searchQuery: String) {
    do {
      self.notes = try self.notesService.fetchNotes(for: searchQuery)
    } catch {
      self.displayAlert(message: error.localizedDescription)
    }
  }

  private func showOnlyNotesOfDateDay(_ date: Date) {
    do {
      self.notes = try self.notesService.fetchNotes(for: date)
    } catch {
      self.displayAlert(message: error.localizedDescription)
    }
  }

  private func notifyDelegateAboutNewContentHeightAndSaveIt() {
    let newContentHeight = self.tableView.contentSize.height
    if newContentHeight != self.savedTableContenHeight {
      self.delegate?.notesListViewController?(self, didUpdate: newContentHeight)
      self.savedTableContenHeight = newContentHeight
    }
  }

  private func setupSearchController() {
    self.tableView.tableHeaderView = self.searchController.searchBar
    self.searchController.searchBar.delegate = self
    self.searchController.obscuresBackgroundDuringPresentation = false
//    searchController.hidesNavigationBarDuringPresentation = false
    self.definesPresentationContext = true
  }

  private func setImage(for note: Note, in cell: NoteTableViewCell) {
    guard let image = note.image,
      let remoteURL = image.remoteURL,
      image.jpegData == nil else { return }

    self.notesService.image(with: remoteURL, for: note) { result in
      switch result {
      case .success(let data):
        DispatchQueue.main.async { cell.setImage(with: data) }
      case .failure:
        break
      }
    }
  }

  // MARK: - UITableView

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.notes.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let note = self.notes[indexPath.row]

    if let title = note.title, !title.isEmpty, note.image != nil, let content = note.content, !content.isEmpty {
      let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.noteTitleImageContent, for: indexPath)!
      cell.configure(with: note)
      self.setImage(for: note, in: cell)
      return cell
    } else if let title = note.title, !title.isEmpty, note.image != nil {
      let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.noteTitleImage, for: indexPath)!
      cell.configure(with: note)
      self.setImage(for: note, in: cell)
      return cell
    } else if let title = note.title, !title.isEmpty, let content = note.content, !content.isEmpty {
      let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.noteTitleContent, for: indexPath)!
      cell.configure(with: note)
      self.setImage(for: note, in: cell)
      return cell
    } else if note.image != nil, let content = note.content, !content.isEmpty {
      let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.noteImageContent, for: indexPath)!
      cell.configure(with: note)
      self.setImage(for: note, in: cell)
      return cell
    } else if let title = note.title, !title.isEmpty {
      let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.noteTitle, for: indexPath)!
      cell.configure(with: note)
      self.setImage(for: note, in: cell)
      return cell
    } else if note.image != nil {
      let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.noteImage, for: indexPath)!
      cell.configure(with: note)
      self.setImage(for: note, in: cell)
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.noteContent, for: indexPath)!
      cell.configure(with: note)
      self.setImage(for: note, in: cell)
      return cell
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.delegate?.notesListViewController?(self, didSelectNoteWith: notes[indexPath.row].localID)
  }
}

extension NotesListViewController: UISearchBarDelegate {

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.fetchNotes(for: searchBar.text!)
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    self.updateNotesList()
  }
}
