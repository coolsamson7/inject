//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class TypesTest: XCTestCase {
    // MARK: local classes

    class PositiveInteger : NumericTypeDescriptor<Int> {
        // init

        init() {
            super.init(constraint: PositiveInteger.greaterEqual(0))
        }
    }
    
    class RangeInteger : NumericTypeDescriptor<Int> {
        // init
        
        init() {
            super.init(constraint: PositiveInteger.greaterEqual(0) && PositiveInteger.lessEqual(10))
        }
    }
    
    class Str10 : StringTypeDescriptor {
        init() {
            super.init(constraint: Str10.length(10))
        }
    }
    
    class Foo : Initializable {
        var name : String = ""
    
        required init() {
        }
    }

    // MARK: tests

    func testTypes() {
        let positiveInteger = PositiveInteger()

        XCTAssert(positiveInteger.isValid(0))
        XCTAssert(!positiveInteger.isValid(-1))
        
        let range = RangeInteger()
        
        XCTAssert(range.isValid(0))
        
        let name = try! BeanDescriptor.forClass(Foo.self)["name"].type(Str10())

        XCTAssert(!name.isValid(0))

        XCTAssert(name.isValid("0"))
        
        XCTAssert(name.isValid("1234567890"))
        
        XCTAssert(!name.isValid("12345678901"))
    }
}