//
//  CreateNoteResponse.swift
//  Diary
//
//  Created by Vladimir Pavlov on 03/10/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

struct CreateNoteResponse: Decodable {

  let remoteID: UInt
  let localID: String

  enum CodingKeys: String, CodingKey {
    case remoteID = "remote_id"
    case localID = "local_id"
  }
}
