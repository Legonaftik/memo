//
//  UserPreferencesStorage.swift
//  Diary
//
//  Created by Vladimir Pavlov on 03/06/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

protocol IUserPreferencesStorage: class {

  var lastNotesSyncDate: Date? { get set }
}

final class UserPreferencesStorage: IUserPreferencesStorage {

  enum Key: String {
    case lastNotesSyncDate
  }

  private let userDefaults = UserDefaults.standard

  var lastNotesSyncDate: Date? {
    get {
      return userDefaults.value(forKey: Key.lastNotesSyncDate.rawValue) as? Date
    }
    set {
      userDefaults.set(newValue, forKey: Key.lastNotesSyncDate.rawValue)
    }
  }
}
