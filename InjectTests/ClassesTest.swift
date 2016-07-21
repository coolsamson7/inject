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

@objc
class TestAnnotadedObjectClass : NSObject {
    
}

@objc(TestAnnotadedNamedObjectClass)
class TestAnnotadedNamedObjectClass : NSObject {
    
}

class ClassesTests: XCTestCase {
    // how about a local class Name

    class LocalClass : NSObject {
    }

    // MARK: local classes

    func testClass4Name() {
        Classes.setDefaultBundle(ClassesTests.self)

        for name in [
            "TestClass",
            "TestObjectClass",
            "TestAnnotadedObjectClass",
            "TestAnnotadedNamedObjectClass",
            "ClassesTests.LocalClass",
            "InjectTests.ClassesTests.LocalClass",
            "InjectTests.ClassesTests#LocalClass",
            "InjectTests.ClassesTests$LocalClass"
        ] {
        do {
           let clazz = try Classes.class4Name(name)
        }
        catch ClassesErrors.Exception(let message) {
            print("##### " + message)
        }
        catch {
            print("##### ocuh")
        }
        } // for
    }
}
