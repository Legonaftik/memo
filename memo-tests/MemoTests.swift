//
//  Created by Vladimir Pavlov on 28/04/2019.
//  Copyright © 2019 Vladimir Pavlov. All rights reserved.
//

import XCTest
@testable import memo

class MemoTests: XCTestCase {

    func test_R() {
        do {
            try R.validate()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
