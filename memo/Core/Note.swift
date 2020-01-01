//
//  Created by Vladimir Pavlov on 25/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

struct Note {
    let localID: UUID
    let content: String?
    let creationDate: Date
    var image: MemoImage?
    let mood: UInt8
    let title: String?
}
