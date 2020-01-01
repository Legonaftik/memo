//
//  Created by Vladimir Pavlov on 02.01.2020.
//  Copyright © 2020 Vladimir Pavlov. All rights reserved.
//

import Foundation

final class NoteValidator {

    func isValid(note: Note) -> Bool {
        if let title = note.title, !title.isEmpty { return true }
        if note.image != nil { return true }
        if let content = note.content, !content.isEmpty { return true }
        return false
    }
}
