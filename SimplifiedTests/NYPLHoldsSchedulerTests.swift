//
//  NYPLHoldsSchedulerTests.swift
//  SimplyETests
//
//  Created by Vui Nguyen on 10/2/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLHoldsSchedulerTests: XCTestCase {

  let holdsScheduler = NYPLHoldsScheduler()

  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testGetMyBooks() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    holdsScheduler.getMyBooks()
  }

}
