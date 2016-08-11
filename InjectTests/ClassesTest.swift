//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

func foo() -> Int {
    print("called foo")
    return 1
}

class TestClass {
    static var i = foo()

    func bar() {
      var j = TestClass.i
    }
}

class TestObjectClass : NSObject {
    static var i = foo()
}

class ClassesTests: XCTestCase {
    // how about a local class Name

    class LocalClass : NSObject {
    }

    func testClass4Name() {
        Classes.setDefaultBundle(ClassesTests.self)

        print("create instance");

        var tc = TestClass()

        print("call bar");

        tc.bar()

        for name in [
            "TestClass",
            "TestObjectClass",
            "ClassesTests.LocalClass",
            "InjectTests.ClassesTests.LocalClass",
            "InjectTests.ClassesTests#LocalClass",
            "InjectTests.ClassesTests$LocalClass"
        ] {
        do {
           try Classes.class4Name(name)
        }
        catch ClassesErrors.Exception(let message) {
            print("##### " + message)
        }
        catch {
            print("##### ouch")
        }
        } // for
    }
}