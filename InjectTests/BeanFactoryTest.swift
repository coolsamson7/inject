//
//  BeanFactoryTests.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class BeanFactoryTests: XCTestCase {
    // MARK: local classes
    
    @objc(Bar)
    class Bar : NSObject {
        var name : String = "andi"
        var age : Int = 51
        var weight : Int = 87
    }
    
    @objc(Data)
    class Data : NSObject , Bean, ClassInitializer {
        // instance data
        
        var string : String = ""
        var int : Int = 0
        var float : Float = 0.0
        var double : Double = 0.0
        var character : Character = Character(" ")
        
        var foo  : FooBase?
        
        // ClassInitializer
        
        func initializeClass() {
            try! BeanDescriptor.forClass(Data.self).getProperty("foo").inject(InjectBean())
        }
        
        // Bean
        
        func postConstruct() -> Void {
            //print("post construct \(self)");
        }
        
        // CustomStringConvertible
        
        override var description : String {
            return "data[string: \(string) foo: \(foo)]"
        }
    }
    
    @objc(FooBase)
    class FooBase : NSObject, Bean {
        // Bean
        
        func postConstruct() -> Void {
            //print("post construct \(self)");
        }
        
        // CustomStringConvertible
        
        override var description : String {
            return "foobase[]"
        }
    }
    
    @objc(Foo)
    class Foo : FooBase {
        var name : String?
        var age : Int = 0
        
        // Bean
        
        override func postConstruct() -> Void {
            //print("post construct \(self)");.auto
        }
        
        // CustomStringConvertible
        
        override var description : String {
            return "foo[name: \(name) age: \(age)]"
        }
    }
    
    // tests
    
    func testBeans() {
        // load parent xml
        
        var data = NSData(contentsOfURL: NSBundle(forClass: BeanFactoryTests.self).URLForResource("parent", withExtension: "xml")!)!
    
        var context = try! ApplicationContext(
            parent: nil,
            data: data,
            namespaceHandlers: [ConfigurationNamespaceHandler(namespace: "configuration")]
        )
        
        // load child
        
        data = NSData(contentsOfURL: NSBundle(forClass: BeanFactoryTests.self).URLForResource("application", withExtension: "xml")!)!
        
        context = try! ApplicationContext(
            parent: context,
            data: data
        )
        
        // check
        
        let bean = try! context.getBean(byId: "b1") as! Data
        
        XCTAssert(bean.string == "b1")
        
        let lazy = try! context.getBean(byId: "lazy") as! Data
        
        XCTAssert(lazy.string == "lazy")
        
        let proto1 = try! context.getBean(byId: "prototype")
        let proto2 = try! context.getBean(byId: "prototype")
        
        XCTAssert(proto1 !== proto2)

        
        let bar = try! context.getBean(byType: Bar.self) as! Bar
        
        XCTAssert(bar.age == 4711)
    }
}
