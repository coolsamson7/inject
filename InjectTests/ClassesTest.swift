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


        func foo(_ o : Any?) -> Any? {
            if o != nil {
                print(type(of: o!))
            }
            return nil
        }

        print(Bundle.main)
        print(Bundle.main.object(forInfoDictionaryKey: "CFBundleName"))

        foo(nil)

        Classes.setDefaultBundle(ClassesTests.self)

        for name in [
            "TestClass",
            "InjectTests_IOS.TestClass",
            "TestObjectClass",
            "ClassesTests.LocalClass",
            "InjectTests.ClassesTests.LocalClass",
            "InjectTests.ClassesTests#LocalClass",
            "InjectTests.ClassesTests$LocalClass"
        ] {
        do {
           try Classes.class4Name(name)
        }
        catch ClassesErrors.exception(let message) {
            print("##### " + message)
        }
        catch {
            print("##### ouch")
        }
        } // for
    }
}
