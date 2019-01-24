//
//  FirebaseAuthService.swift
//  Diary
//
//  Created by Vladimir Pavlov on 06/05/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation
import FirebaseUI

protocol IAuthService {
  func isLoggedIn() -> Bool
  func createAuthScreen() -> UIViewController
  func updateAccessToken(completion: @escaping (Result<String>) -> Void)
  func signOut() throws
}

enum AuthError: Error {
  case noUserInfoAvailable
  case tokenRefreshError(Error?)
}

final class FirebaseAuthService: NSObject, IAuthService {

  private var user: User? {
    return Auth.auth().currentUser
  }

  func isLoggedIn() -> Bool {
    return user != nil
  }

  func createAuthScreen() -> UIViewController {
    let authUI = FUIAuth.defaultAuthUI()!
    authUI.providers = [FUIGoogleAuth()]
    return authUI.authViewController()
  }

  func updateAccessToken(completion: @escaping (Result<String>) -> Void) {
    guard let user = user else {
      completion(.failure(AuthError.noUserInfoAvailable))
      return
    }

    user.getIDToken { token, error in
      guard let token = token else {
        completion(.failure(AuthError.tokenRefreshError(error)))
        return
      }
      completion(.success(token))
    }
  }

  func signOut() throws {
    try Auth.auth().signOut()
  }
}
