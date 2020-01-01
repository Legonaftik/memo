//
//  UIViewController+Keyboard.swift
//  memo
//
//  Created by Vladimir Pavlov on 11/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

extension UIViewController {

  func hideKeyboardWhenTappedAround() {
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(
      target: self, action: #selector(UIViewController.dismissKeyboard))
    tap.cancelsTouchesInView = false
    self.view.addGestureRecognizer(tap)
  }

  func addObserversForKeyboardAppearance() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)),
                                           name: UIResponder.keyboardWillShowNotification, object: self.view.window)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)),
                                           name: UIResponder.keyboardWillHideNotification, object: self.view.window)
  }

  @objc func handleKeyboardNotification(_ notification: NSNotification) {
    if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
        .cgRectValue.height {
      let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
      self.view.frame.origin.y = isKeyboardShowing ? -(keyboardHeight-150) : 0.0
    }
  }

  @objc private func dismissKeyboard() {
    self.view.endEditing(true)
  }
}