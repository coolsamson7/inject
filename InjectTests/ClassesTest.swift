//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class TestClass {
}

class TestObjectClass : NSObject {
}

class ClassesTests: XCTestCase {

    // how about a local class Name

    class LocalClass : NSObject {
    }

    func testClass4Name() {


        func foo(o : Any?) -> Any? {
            if o != nil {
                print(o!.dynamicType)
            }
            return nil
        }

        foo(nil)

        Classes.setDefaultBundle(ClassesTests.self)

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