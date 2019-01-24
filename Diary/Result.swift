//
//  Result.swift
//  Diary
//
//  Created by Vladimir Pavlov on 17/06/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

enum Result<T> {
  case success(T)
  case failure(Error)
}
