//
//  ImageResponse.swift
//  Diary
//
//  Created by Vladimir Pavlov on 05/10/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

struct ImageResponse: Decodable {

  let imageURL: URL

  enum CodingKeys: String, CodingKey {
    case imageURL = "image"
  }
}
