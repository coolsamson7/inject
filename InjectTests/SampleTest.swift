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

    func process(_ bean : AnyObject) throws -> AnyObject {
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

    func initializeBeanDescriptor(_ beanDescriptor : BeanDescriptor) {
        beanDescriptor["bar"].inject(InjectBean())
    }
    
    // CustomStringConvertible
    
    override internal var description: String {
        return "foo[id: \(id), number: \(number), bar: \(String(describing: bar))]"
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

protocol SwiftProtocol {
}

class SampleScope : AbstractBeanScope {
    override init() {
        super.init(name: "sample")
    }

    override func prepare(_ bean : Environment.BeanDeclaration, factory : BeanFactory) throws {
        if !bean.lazy {
            try get(bean, factory: factory)
        }
    }

    override func get(_ bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
        if bean.singleton == nil {
            bean.singleton = try factory.create(bean)
        }

        return bean.singleton!
    }
}

class SampleTest: XCTestCase {
    override class func setUp() {
        Classes.setDefaultBundle(SampleTest.self)

        Tracer.setTraceLevel("inject", level: .full)
        Tracer.setTraceLevel("configuration", level: .full)

        // register the namespace handler.

        ConfigurationNamespaceHandler(namespace: "configuration")

        // logger

        LogManager()
            .registerLogger("", level : .all, logs: [ConsoleLog(name: "console", synchronize: true)])

    }

    // MARK: internal funcs

    func getResource(_ name : String, suffix : String = "xml") -> Foundation.Data {
        return (try! Foundation.Data(contentsOf: Bundle(for: type(of: self)).url(forResource: name, withExtension: suffix)!))
    }

    // tests
    
    /*func testXML() {
        let environment = try! Environment(name: "environment")

        try! environment
           .loadXML(getResource("sample"))
           .startup()


        print(environment.report())

        let baz = try! environment.getBean(Baz.self)
        
        XCTAssert(baz.id == "id")
    }*/


   func testFluent() {
        let environment = try! Environment(name: "fluent environment", traceOrigin: true)

        try! environment.addConfigurationSource(ProcessInfoConfigurationSource())

        try! environment
           .define(environment.bean(Foo.self, id: "foo-by-factory", factory: {return Foo()}))

           .define(environment.bean(SamplePostProcessor.self))

           .define(environment.bean(Foo.self, id: "foo-1")
              .property("id", value: "foo-1")
              .property("number", resolve: "${dunno=1}"))

           .define(environment.bean(Foo.self, id: "foo-prototype")
              .scope("prototype")
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
                .property("id", value: "baz"))

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

       let foos = try! environment.getBeansByType(Foo.self)
    
       XCTAssert(foos.count == 4)

       let baz = try! environment.getBean(Baz.self)


       XCTAssert(baz.id == "baz")
    }


    class Swift : SwiftProtocol, Initializable, BeanDescriptorInitializer {
        var name : String?
        var number : Int = 0
        var other : AnotherSwift?

        // MARK: init

        required init() {
        }

        //  MARK: implement BeanDescriptorInitializer

        func initializeBeanDescriptor(_ beanDescriptor : BeanDescriptor) {
            try! beanDescriptor.implements(SwiftProtocol.self, Initializable.self, BeanDescriptorInitializer.self)
        }
    }

    class AnotherSwift : NSObject, BeanDescriptorInitializer {
        var name : String?
        var number : Int = 0

        //  MARK: init

        override init() {
            super.init()
        }

        //  MARK: implement BeanDescriptorInitializer

        func initializeBeanDescriptor(_ beanDescriptor : BeanDescriptor) {
            beanDescriptor["number"].inject(InjectConfigurationValue(key: "key", defaultValue: -1))

            try! beanDescriptor.implements(BeanDescriptorInitializer.self, Initializable.self)
        }
    }

    func testNoReflection() {
        let environment = try! Environment(name: "no reflection environment")

        try! environment.addConfigurationSource(ProcessInfoConfigurationSource())

        try! environment
           .define(environment.bean(SampleScope.self, factory: SampleScope.init))

           .define(environment.bean(Swift.self, factory: {
               let swift = Swift()

               swift.name = try environment.getConfigurationValue(String.self, key: "dunno", defaultValue: "default")
               swift.other = try environment.getBean(AnotherSwift.self)

               return swift
           })
               .requires(class: AnotherSwift.self)
               .scope("sample")
               .implements(SwiftProtocol.self))

        .define(environment.bean(AnotherSwift.self, factory: AnotherSwift.init))

        // fetch

        let swiftProtocol = try! environment.getBean(SwiftProtocol.self)
        let other = try! environment.getBean(AnotherSwift.self)

        XCTAssert(swiftProtocol is Swift)
        XCTAssert(other.number == -1)

        let swiftProtocols =  try! environment.getBeansByType(SwiftProtocol.self)

        XCTAssert(swiftProtocols.count == 1)

        let initializables = try! environment.getBeansByType(Initializable.self)

        XCTAssert(initializables.count == 2)

        let descriptoInitializers =  try! environment.getBeansByType(BeanDescriptorInitializer.self)

        XCTAssert(descriptoInitializers.count == 2)
    }

    // FOO

    // TEST

    // test classes

    class B {
        init() {
            print("B");
        }
    }

    class A {
        init() {
            print("A");
        }
    }

    class TestModuleA : EnvironmentBuilder.Module {
        // init
        
        required init() {
            super.init(name: "module A")
        }
        
        // implement Module
        
        override func configure(_ environment : Environment) throws -> Void {
            // require...

            // own dependencies

            try environment.define(bean(A.self, factory: A.init))
        }
    }

    class TestModuleB : EnvironmentBuilder.Module {
        // init
        
        required init() {
            super.init(name: "module B")
        }
        
        // implement Module

        override func configure(_ environment : Environment) throws -> Void {
            // require...

            try require(TestModuleA.self);

            //finish();

            // own dependencies

            try environment.define(bean(B.self, factory: B.init))
        }
    }

    func testEnvironment() throws {
        let builder = EnvironmentBuilder(name: "environment");

        // register a couple of environments

        try builder.register(module: TestModuleA());
        //try builder.register(module: TestModuleB.self);

        // go

        let environment = try builder.build(module: TestModuleB());//.self);

        print(environment.report());
    }
}
