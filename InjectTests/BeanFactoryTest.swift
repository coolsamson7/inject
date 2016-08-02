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

class BarFactory : NSObject, FactoryBean {
    func create() throws -> AnyObject {
        let result = Bar()

        result.name = "factory"
        result.age = 4711

        return result
    }
}

class Bar : NSObject {
    var name : String = "andi"
    var age : Int = 51
    var weight : Int = 87
}

class Data : NSObject , Bean, ClassInitializer {
    // instance data

    var string : String = ""
    var int : Int = 0
    var float : Float = 0.0
    var double : Double = 0.0
    var character : Character = Character(" ")

    var foo  : FooBase?
    var bar  : Bar?

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

class BeanFactoryTests: XCTestCase {
    // tests
    
    func testXML() {
        Classes.setDefaultBundle(self.dynamicType)

        Tracer.setTraceLevel("loader", level: .FULL)

        ConfigurationNamespaceHandler(namespace: "configuration")

        // load parent xml

        let parentData = NSData(contentsOfURL: NSBundle(forClass: BeanFactoryTests.self).URLForResource("parent", withExtension: "xml")!)!
        let childData  = NSData(contentsOfURL: NSBundle(forClass: BeanFactoryTests.self).URLForResource("application", withExtension: "xml")!)!

        var context = try! ApplicationContext(parent: nil)

        try! context.loadXML(parentData)
        
        // load child

        context = try! ApplicationContext(parent: context)

        try! context.loadXML(childData)
        
        // check
        
        let bean : Data = try! context.getBean(Data.self, byId: "b1")
        
        XCTAssert(bean.string == "b1")
        
        let lazy = try! context.getBean(Data.self, byId: "lazy")
        
        XCTAssert(lazy.string == "lazy")
        
        let proto1 = try! context.getBean(Data.self, byId: "prototype")
        let proto2 = try! context.getBean(Data.self, byId: "prototype")
        
        XCTAssert(proto1 !== proto2)

        
        let bar = try! context.getBean(Bar.self)
        
        XCTAssert(bar.age == 4711)

        // Measure

        try! Timer.measure({
            var context = try! ApplicationContext()

            try! context.loadXML(parentData)

            // load child

            context = try! ApplicationContext(parent: context)

            try! context.loadXML(childData)

            return true
        }, times: 1000)

    }

    func testFluent() {
        Classes.setDefaultBundle(self.dynamicType)

        let parent = try! ApplicationContext(parent: nil)

        try! parent
           .define(parent.bean(ProcessInfoConfigurationSource.self)
              .id("x1"))

           .define(parent.bean(Data.self)
              .id("b0")
              .property("string", value: "b0")
              .property("int", value: 1)
              .property("float", value: Float(-1.1))
              .property("double", value: Double(-2.2)))

           .define(parent.bean(Foo.self)
               .id("foo")
               .property("name", resolve: "${andi=Andreas?}")
               .property("age", resolve: "${SIMULATOR_MAINSCREEN_HEIGHT=51}")) // TODO?

           /*.define(parent.bean(Bar.self)
               .id("bar")
               .abstract()
               .property("name", resolve: "${andi=Andreas?}"))
*/
        let child = try! ApplicationContext(parent: parent)

        try! child
            .define(child.bean(Data.self)
                .id("b1")
                .dependsOn("b0")
                .property("foo", inject: InjectBean(id: "foo"))
                .property("string", value: "b1")
                .property("int", value: 1)
                .property("float", value: Float(1.1))
                .property("double", value: Double(2.2)))

            .define(child.bean(Data.self)
                .id("lazy")
                .lazy()
                .property("bar", bean: child.bean(Bar.self)
                      .property("name", value: "name")
                      .property("age", value: 0)
                )
                .property("string", value: "lazy")
                .property("int", value: 1)
                .property("float", value: Float(1.1))
                .property("double", value: Double(2.2)))

            .define(child.bean(Data.self)
                .id("prototype")
                .scope(child.scope("prototype"))
                .property("string", value: "b1")
                .property("int", value: 1)
                .property("float", value: Float(1.1))
                .property("double", value: Double(2.2)))

             //.define(child.bean(BarFactory.self)
             //   .target("Bar"))

        // check

        let bean : Data = try! child.getBean(Data.self, byId: "b1")

        XCTAssert(bean.string == "b1")

        let lazy = try! child.getBean(Data.self, byId: "lazy")

        XCTAssert(lazy.string == "lazy")

        let proto1 = try! child.getBean(Data.self, byId: "prototype")
        let proto2 = try! child.getBean(Data.self, byId: "prototype")

        XCTAssert(proto1 !== proto2)

        let bar = try! child.getBean(Bar.self)

        XCTAssert(bar.age == 4711)

        let foo = try! child.getBean(Foo.self, byId: "foo")

        //XCTAssert(bar.age == 4711)
    }
}
