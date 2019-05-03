//
//  AuthViewController.swift
//  memo
//
//  Created by Vladimir Pavlov on 04/10/2017.
//  Copyright © 2017 Vladimir Pavlov. All rights reserved.
//

import UIKit
import LocalAuthentication

final class AuthViewController: UIViewController {

  @IBAction private func logIn() {
    self.startLocalAuthentication()
  }

  private func startLocalAuthentication() {
    let authenticationContext = LAContext()

    var error: NSError?
    guard authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      assertionFailure("Tried to process biometric auth on a device which doesn't support it.")
      return
    }

    authenticationContext.evaluatePolicy(
      .deviceOwnerAuthenticationWithBiometrics,
      localizedReason: R.string.localizable.authorizeToAccessYourDiary(),
      reply: { [unowned self] success, error in
        DispatchQueue.main.async {
          if success {
//            self.performSegue(withIdentifier: "toMain", sender: nil)
          } else {
            self.displayAlert(message: error!.localizedDescription)
          }
        }
    })
  }
}
