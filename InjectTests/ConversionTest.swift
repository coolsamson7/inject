//
//  ConversionTest.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class ConversionTest: XCTestCase {
    override class func setUp() {
        Classes.setDefaultBundle(ConversionTest.self)

        // set tracing

        Tracer.setTraceLevel("inject", level: .full)

        // set logging

        LogManager()
           .registerLogger("", level : .all, logs: [QueuedLog(name: "async-console", delegate: ConsoleLog(name: "console", synchronize: false))])
    }

    // tests
    
    func testConversion() {
        let string2int = try! StandardConversionFactory.instance.getConversion(String.self, targetType: Int.self)

        let result = try! string2int(object: "4711") as! Int // no generics here...

        XCTAssert(result == 4711)

    }
}
