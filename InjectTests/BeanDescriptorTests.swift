//
//  BeanDescriptorTests.swift
//  InjectTests
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject


class BeanDescriptorTests: XCTestCase {
    // MARK: local classes
    
    class Foo : NSObject {
        // instance data
        
        var string : String = ""
        var int : Int = 0
        var float : Float = 0.0
        var double : Double = 0.0
    }

    func testProperties() {
        let bean = BeanDescriptor.forClass(Foo.self)
        
        let foo = Foo()
        
        try! bean["string"].set(foo, value: "hello")
        try! bean["int"].set(foo, value: 1)
        try! bean["float"].set(foo, value: 1.0)
        try! bean["double"].set(foo, value: 1.0)

        XCTAssert(bean["string"].get(foo) as! String == "hello")


        XCTAssert(foo.string == "hello")
        XCTAssert(foo.int == 1)
        XCTAssert(foo.float == 1.0)
        XCTAssert(foo.double == 1.0)
    }
}
