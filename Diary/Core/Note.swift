//
//  Note.swift
//  Diary
//
//  Created by Vladimir Pavlov on 25/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

struct Note: Codable {

  let localID: UUID
  var remoteID: UInt?
  let content: String?
  let creationDate: Date
  var image: MemoImage?
  let mood: UInt8
  let title: String?
  var isSynced = false
  var toBeDeleted = false

  init(localID: UUID, remoteID: UInt?, content: String?,
       creationDate: Date, image: MemoImage?, mood: UInt8,
       title: String?, isSynced: Bool = false, toBeDeleted: Bool = false) {
    self.localID = localID
    self.remoteID = remoteID
    self.content = content
    self.creationDate = creationDate
    self.image = image
    self.mood = mood
    self.title = title
    self.isSynced = isSynced
    self.toBeDeleted = toBeDeleted
  }

  // MARK: - Codable

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    localID = try container.decode(UUID.self, forKey: .localID)
    // remoteID is not optional in this case since it has to be present when we get the value from backend.
    // Otherwise it is a business logic error.
    remoteID = try container.decode(UInt.self, forKey: .remoteID)
    content = try? container.decode(String.self, forKey: .content)
    creationDate = try container.decode(Date.self, forKey: .creationDate)
    if let remoteURL = try? container.decode(URL.self, forKey: .image) {
      image = MemoImage(jpegData: nil, remoteURL: remoteURL)
    } else {
      image = nil
    }
    mood = try container.decode(UInt8.self, forKey: .mood)
    title = try? container.decode(String.self, forKey: .title)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(localID, forKey: .localID)
    try? container.encode(remoteID, forKey: .remoteID)
    try? container.encode(content, forKey: .content)
    try container.encode(creationDate, forKey: .creationDate)
    // image is not encoded since we use a separate request for images
    try container.encode(mood, forKey: .mood)
    try? container.encode(title, forKey: .title)
  }

  private enum CodingKeys: String, CodingKey {
    case localID = "local_id"
    case remoteID = "remote_id"
    case content = "text"
    case creationDate = "date"
    case mood
    case image
    case title
  }
}
