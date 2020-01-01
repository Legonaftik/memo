//
//  Created by Vladimir Pavlov on 02.01.2020.
//  Copyright © 2020 Vladimir Pavlov. All rights reserved.
//

import Foundation

final class MoodPredictor {

    func mood(for note: Note) -> Int8 {
        return Int8.random(in: 0...4)
    }
}
