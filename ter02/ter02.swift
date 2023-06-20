//
//  ter02.swift
//  ter02
//
//  Created by bill donner on 6/19/23.
//

import XCTest

final class ter02: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
  
  func testStripComments() throws {
    
    func stripComments(source: String, commentStart: String) -> String {
      let lines = source.split(separator: "\n")
      var keeplines:[String] = []
      for line in lines  {
        if !line.hasPrefix(commentStart) {
          keeplines += [String(line)]
        }
      }
      return keeplines.joined(separator: "\n")
    }
    let s = """
***testing
"""
    let y = stripComments ( source:s, commentStart:"***")
    XCTAssert(y=="","leftovers \(y)")
    let  t = """
***testing
testing123
***more testing
testing456

"""
    let z = stripComments ( source:t, commentStart:"***")
    XCTAssert(z=="testing123\ntesting456","yikes \(z)")
    
  }

}
