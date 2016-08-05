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

class BarFactoryBean: NSObject, FactoryBean {
    func create() throws -> AnyObject {
        let result = BarBean()

        result.name = "factory"
        result.age = 4711

        return result
    }
}

class BarBean: NSObject {
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
    var int8 : Int8 = 0

    var foo  : FooBase?
    var bar  : BarBean?

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

class FooBean: FooBase {
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
    override class func setUp() {
        Classes.setDefaultBundle(BeanFactoryTests.self)

        Tracer.setTraceLevel("inject", level: .FULL)
    }

    // tests
    
    func testXML() {
        ConfigurationNamespaceHandler(namespace: "configuration")

        // load parent xml

        let parentData = NSData(contentsOfURL: NSBundle(forClass: BeanFactoryTests.self).URLForResource("parent", withExtension: "xml")!)!
        let childData  = NSData(contentsOfURL: NSBundle(forClass: BeanFactoryTests.self).URLForResource("application", withExtension: "xml")!)!

        var environment = try! Environment(name: "parent")

        try! environment.loadXML(parentData)
        
        // load child

        environment = try! Environment(name: "parent", parent: environment)

        try! environment.loadXML(childData)
        
        // check
        
        let bean : Data = try! environment.getBean(Data.self, byId: "b1")
        
        XCTAssert(bean.string == "b1")
        
        let lazy = try! environment.getBean(Data.self, byId: "lazy")
        
        XCTAssert(lazy.string == "lazy")
        
        let proto1 = try! environment.getBean(Data.self, byId: "prototype")
        let proto2 = try! environment.getBean(Data.self, byId: "prototype")
        
        XCTAssert(proto1 !== proto2)

        
        let bar = try! environment.getBean(BarBean.self)
        
        XCTAssert(bar.age == 4711)

        // Measure

        if true {
            try! Timer.measure({
                var environment = try! Environment(name: "parent")

                try! environment.loadXML(parentData)

                // load child

                environment = try! Environment(name: "child", parent: environment)

                try! environment.loadXML(childData)

                // force load!

                try! environment.getBean(BarBean.self)

                return true
            }, times: 1000)
        }

    }

    func testFluent() throws {
        let parent = try Environment(name: "parent")

        try parent.getConfigurationManager().addSource(ProcessInfoConfigurationSource())

        try parent
           //.define(parent.bean(ProcessInfoConfigurationSource.self)
           //   .id("x1"))

           .define(parent.bean(Data.self)
              .id("b0")
              .property("string", value: "b0")
              .property("int", value: 1)
              .property("float", value: Float(-1.1))
              .property("double", value: -2.2))

           .define(parent.bean(FooBean.self)
               .id("foo")
               .property("name", resolve: "${andi=Andreas?}")
               .property("age", resolve: "${SIMULATOR_MAINSCREEN_HEIGHT=51}")) // TODO?

           /*.define(parent.bean(Bar.self)
               .id("bar")
               .abstract()
               .property("name", resolve: "${andi=Andreas?}"))
*/
        let child = try! Environment(name: "child", parent: parent)

        try! child
            .define(child.bean(Data.self)
                .id("b1")
                .dependsOn("b0")
                .property("foo", inject: InjectBean(id: "foo"))
                .property("string", value: "b1")
                .property("int", value: 1)
                .property("int8", value: Int8(1))
                .property("float", value: Float(1.1))
                .property("double", value: 2.2))

            .define(child.bean(Data.self)
                .id("lazy")
                .lazy()
                .property("bar", bean: child.bean(BarBean.self)
                      .property("name", value: "name")
                      .property("age", value: 0)
                )
                .property("string", value: "lazy")
                .property("int", value: 1)
                .property("float", value: Float(1.1))
                .property("double", value: 2.2))

            .define(child.bean(Data.self)
                .id("prototype")
                .scope(child.scope("prototype"))
                .property("string", value: "b1")
                .property("int", value: 1)
                .property("float", value: Float(1.1))
                .property("double", value: 2.2))

             //.define(child.bean(BarFactory.self)
             //   .target("Bar"))

        print(parent.getConfigurationManager().report())

        // check

        let bean : Data = try! child.getBean(Data.self, byId: "b1")

        XCTAssert(bean.string == "b1")

        let lazy = try! child.getBean(Data.self, byId: "lazy")

        XCTAssert(lazy.string == "lazy")

        let proto1 = try! child.getBean(Data.self, byId: "prototype")
        let proto2 = try! child.getBean(Data.self, byId: "prototype")

        XCTAssert(proto1 !== proto2)

        let bar = try! child.getBean(BarBean.self)

        XCTAssert(bar.age == 0)

        let foo = try! child.getBean(FooBean.self, byId: "foo")

        //XCTAssert(bar.age == 4711)
    }
}
