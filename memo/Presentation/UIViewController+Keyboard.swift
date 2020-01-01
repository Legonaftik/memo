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
        view.addGestureRecognizer(tap)
    }

    func addObserversForKeyboardAppearance() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: self.view.window)
    }

    @objc
    func handleKeyboardNotification(_ notification: NSNotification) {
        guard
            let userInfo = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)
        else {
            return
        }

        let keyboardHeight = userInfo.cgRectValue.height
        let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
        view.frame.origin.y = isKeyboardShowing ? -(keyboardHeight-150) : 0.0
    }

    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
}
