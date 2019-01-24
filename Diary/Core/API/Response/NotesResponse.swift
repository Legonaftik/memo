//
//  NotesResponse.swift
//  Diary
//
//  Created by Vladimir Pavlov on 26/05/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

struct NotesResponse: Decodable {

  let updated: [Note]
  let remoteIDs: [UInt]

  enum CodingKeys: String, CodingKey {
    case updated
    case remoteIDs = "notes_id"
  }
}
