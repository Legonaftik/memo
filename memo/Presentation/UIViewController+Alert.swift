//
//  UIViewController+Alert.swift
//  memo
//
//  Created by Vladimir Pavlov on 11/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import UIKit

extension UIViewController {

  func displayAlert(title: String = R.string.localizable.warning(), message: String? = nil,
                    completion: (() -> Void)? = nil) {
    let alertController = UIAlertController(title: title, message: message,
                                            preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(okAction)
    self.present(alertController, animated: true, completion: completion)
  }
}
