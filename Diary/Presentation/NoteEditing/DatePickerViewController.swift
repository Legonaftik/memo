//
//  DatePickerViewController.swift
//  Diary
//
//  Created by Vladimir Pavlov on 11/03/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

protocol DatePickerViewControllerDelegate: class {
  func datePicker(_ datePicker: DatePickerViewController, didSelect date: Date)
}

final class DatePickerViewController: UIViewController {

  weak var delegate: DatePickerViewControllerDelegate?

  @IBOutlet private var datePicker: UIDatePicker!

  @IBAction private func cancel(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction private func done(_ sender: UIBarButtonItem) {
    self.delegate?.datePicker(self, didSelect: self.datePicker.date)
    self.dismiss(animated: true, completion: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.datePicker.maximumDate = Date()
  }
}
