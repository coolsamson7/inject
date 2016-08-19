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


// test classes

class SamplePostProcessor : NSObject, BeanPostProcessor {
    // implement BeanPostProcessor

    func process(bean : AnyObject) throws -> AnyObject {
        print("post process \(bean)...")

        return bean
    }
}

class Foo : NSObject, Bean, BeanDescriptorInitializer {
    // instance data

    var id : String = ""
    var number : Int = 0
    var bar : Bar?

    // init

    override init() {
        super.init()
    }

    // implement Bean

    func postConstruct() throws -> Void {
        // funny code here
    }

    // implement BeanDescriptorInitializer

    func initializeBeanDescriptor(beanDescriptor : BeanDescriptor) {
        beanDescriptor["bar"].inject(InjectBean())
    }
}

class Bar : NSObject, EnvironmentAware {
    // instance data

    var id : String = ""
    var magic = 0

    // init

    override init() {
        super.init()
    }

    // implement EnvironmentAware

    var _environment : Environment?

    var environment: Environment? {
        get {
            return _environment
        }
        set {
            _environment = newValue
        }
    }
}

class BazFactory : NSObject, FactoryBean {
    // instance data

    var name : String = ""
    var id : String = ""

    // init

    override init() {
        super.init()
    }

    // implement FactoryBean

    func create() throws -> AnyObject {
        let result = Baz()

        result.factory = name
        result.id = id

        return result
    }
}

class Baz : NSObject {
    // instance data

    var factory : String = ""
    var id : String = ""

    // init

    override init() {
        super.init()
    }
}

class Bazong : NSObject {
    // instance data

    var id : String = ""
    var foo : Foo? = nil

    // init

    override init() {
        super.init()
    }
}

class SampleTest: XCTestCase {
    override class func setUp() {
        Classes.setDefaultBundle(SampleTest.self)

        Tracer.setTraceLevel("inject", level: .FULL)
        Tracer.setTraceLevel("configuration", level: .FULL)

        // register the namespace handler.

        ConfigurationNamespaceHandler(namespace: "configuration")

        // logger

        LogManager()
            .registerLogger("", level : .ALL, logs: [ConsoleLog(name: "console", synchronize: true)])

    }

    // MARK: internal funcs

    func getResource(name : String, suffix : String = "xml") -> NSData {
        return NSData(contentsOfURL: NSBundle(forClass: self.dynamicType).URLForResource(name, withExtension: suffix)!)!
    }

    // tests
    
    func testXML() {
        let environment = try! Environment(name: "environment")

        try! environment
           .loadXML(getResource("sample"))
           .startup()


        print(environment.report())

        var baz = try! environment.getBean(Baz.self)
    }

    // TODO: + explicit dependency + factory sample!
   func testFluent() {
        let environment = try! Environment(name: "fluent environment")

        try! environment.addConfigurationSource(ProcessInfoConfigurationSource())

        try! environment
           .define(environment.bean(Foo.self, id: "foo-by-factory", factory: {return Foo()}))

           .define(environment.bean(SamplePostProcessor.self))

           .define(environment.bean(Foo.self, id: "foo-1")
               .property("id", value: "foo-1")
               .property("number", resolve: "${dunno=1}"))

           .define(environment.bean(Foo.self, id: "foo-prototype")
              .scope(environment.scope("prototype"))
              .property("id", value: "foo-prototype")
              .property("number", resolve: "${com.foo:bar=1}"))

           .define(environment.bean(Bar.self, id: "bar-parent")
               .abstract()
               .property("magic", value: 4711))

            .define(environment.bean(Bar.self, id: "bar")
               .parent("bar-parent")
               .property("id", value: "bar"))

             .define(environment.bean(BazFactory.self, id: "baz")
                .target(Baz.self)
                .property("name", value: "factory")
                .property("id", value: "id"))

             .define(environment.bean(Bazong.self, id: "bazong-1")
                .property("id", value: "id")
                .property("foo", ref: "foo-1"))

             .define(environment.bean(Bazong.self, id: "bazong-2")
                .property("id", value: "id")
                .property("foo", bean: environment.bean(Foo.self)
                     .property("id", value: "foo-3")
                     .property("number", value: 1)))

            .startup()

       print(environment.report())

       var foos = try! environment.getBeansByType(Foo.self)

       var baz = try! environment.getBean(Baz.self)
    }

    class Swift : Initializable {
        var name : String?
        var number : Int = 0
        var other : AnotherSwift?

        // Initializable

        required init() {
        }
    }

    class AnotherSwift : Initializable {
        var name : String?
        var number : Int = 0

        // Initializable

        required init() {
        }
    }

    func testNoReflection() {
        let environment = try! Environment(name: "no reflection environment")

        try! environment.addConfigurationSource(ProcessInfoConfigurationSource())

        try! environment
           .define(environment.bean(Swift.self, factory: {
            let swift = Swift()

            swift.name = try environment.getValue(String.self, key: "dunno", defaultValue: "default")
            swift.other = try environment.getBean(AnotherSwift.self)

            return swift
        }).requires(class: AnotherSwift.self))

        .define(environment.bean(AnotherSwift.self, factory: AnotherSwift.init/*{
            let swift = AnotherSwift()

            swift.name = "other swift"

            return swift
        }*/))

        // fetch

        let swift = try! environment.getBean(Swift.self)
    }
}
