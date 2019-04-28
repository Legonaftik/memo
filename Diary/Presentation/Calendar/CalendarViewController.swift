//
//  CalendarViewController.swift
//  Diary
//
//  Created by Vladimir Pavlov on 17/03/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit
import FSCalendar

final class CalendarViewController: UIViewController {

  var notesService: IAuthorizedNoteServiceFacade!

  @IBOutlet private var calendarView: FSCalendar!
  @IBOutlet private var notesListHeightConstraint: NSLayoutConstraint!

  private var dailyNotesInfo: [Date: (UInt, UInt)] = [:] {
    didSet { self.calendarView.reloadData() }
  }
  private var notesListViewController: NotesListViewController?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.calendarView.today = nil
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    do {
      self.dailyNotesInfo = try self.notesService.dailyNotesInfo()
    } catch {
      self.displayAlert(message: error.localizedDescription)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let notesListSegue = R.segue.calendarViewController.notesList(segue: segue) {
      let notesListVC = notesListSegue.destination
      notesListVC.notesService = self.notesService
      notesListVC.tableView.isScrollEnabled = false
      notesListVC.tableView.tableHeaderView = nil
      notesListVC.delegate = self
      // Stored as a local property so we can pass it days selection events
      self.notesListViewController = notesListVC
    } else if let noteDetailsSegue = R.segue.calendarViewController.noteDetails(segue: segue) {
      noteDetailsSegue.destination.notesService = self.notesService
      noteDetailsSegue.destination.noteID = (sender as! UUID)
    }
  }
}

extension CalendarViewController: FSCalendarDelegate {

  func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
    self.notesListViewController?.dateToDisplay = date
  }

  func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
    return (self.dailyNotesInfo[date]?.0 ?? 0) != 0
  }
}

extension CalendarViewController: FSCalendarDataSource {

  func minimumDate(for calendar: FSCalendar) -> Date {
    return Date(timeIntervalSinceReferenceDate: 0)
  }

  func maximumDate(for calendar: FSCalendar) -> Date {
    return Date()
  }

  func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
    return Int(self.dailyNotesInfo[date]?.0 ?? 0)
  }

  func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
    let cell = calendar.dequeueReusableCell(withIdentifier: FSCalendarDefaultCellReuseIdentifier,
                                            for: date, at: position)
    if (self.dailyNotesInfo[date]?.0 ?? 0) != 0 {
      cell.alpha = 1
    } else {
      cell.alpha = 0.5
    }
    return cell
  }
}

extension CalendarViewController: NotesListViewControllerDelegate {

  func notesListViewController(_ notesListVC: NotesListViewController, didSelectNoteWith localID: UUID) {
    self.performSegue(withIdentifier: R.segue.calendarViewController.noteDetails, sender: localID)
  }

  func notesListViewController(_ notesListVC: NotesListViewController, didUpdate contentHeight: CGFloat) {
    self.notesListHeightConstraint.constant = contentHeight
  }
}
