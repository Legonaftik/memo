//
//  ServerTimeResponse.swift
//  memo
//
//  Created by Vladimir Pavlov on 26/05/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

struct ServerTimeResponse: Decodable {

  let serverTime: Date

  enum CodingKeys: String, CodingKey {
    case serverTime = "server_time"
  }
}
