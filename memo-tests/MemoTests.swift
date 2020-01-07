//
//  MemoTests.swift
//  memo-tests
//
//  Created by Vladimir Pavlov on 28/04/2019.
//  Copyright © 2019 Vladimir Pavlov. All rights reserved.
//

import XCTest
import Rswift

class MemoTests: XCTestCase {

    func testExample() {
        do {
          try R.validate()
        } catch {
            XCTFail(error)
        }
    }
}
