//
//  EnvironmentModule.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

open class EnvironmentModule {
    // MARK: instance data

    var name : String
    var traceOrigin = false

    // MARK: init

    init(name : String) {
        self.name = name
    }

    // MARK: convenience

    /// create a `BeanDeclaration` based on a already constructed object
    /// - Parameter instance: the corresponding instance
    /// - Parameter id: an optional id
    /// - Returns: the new `BeanDeclaration`
    open func bean(_ instance : AnyObject, id : String? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration(instance: instance)

        if id != nil {
            result.id = id
        }

        if traceOrigin {
            result.origin = Origin(file: file, line: line, column: column)
        }

        return result
    }

    /// create a `BeanDeclaration`
    /// - Parameter className: the name of the bean class
    /// - Parameter id: an optional id
    /// - Parameter lazy: the lazy attribute. default is `false`
    /// - Parameter abstract: the abstract attribute. default is `false`
    /// - Returns: the new `BeanDeclaration`
    open func bean(_ className : String, id : String? = nil, lazy : Bool = false, abstract : Bool = false, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        if traceOrigin {
            result.origin = Origin(file: file, line: line, column: column)
        }

        result.lazy = lazy
        result.abstract = abstract

        result.clazz = try Classes.class4Name(className)

        return result
    }

    /// create a `BeanDeclaration`
    /// - Parameter clazz: the bean class
    /// - Parameter id: an optional id
    /// - Parameter lazy: the lazy attribute. default is `false`
    /// - Parameter abstract:t he abstract attribute. default is `false`
    /// - Parameter factory: a factory function that will return a new instance of the specific type
    /// - Returns: the new `BeanDeclaration`
    open func bean<T>(_ clazz : T.Type, id : String? = nil, lazy : Bool = false, abstract : Bool = false, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, factory : (() throws -> T)? = nil) throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        if traceOrigin {
            result.origin = Origin(file: file, line: line, column: column)
        }

        result.lazy = lazy
        result.abstract = abstract

        if factory != nil {
            result.factory = FactoryFactory<T>(factory: factory!)
        }

        if let anyClass = clazz as? AnyClass {
            result.clazz = anyClass

        }
        else {
            throw EnvironmentErrors.exception(message: "only classes are accepted, got \(clazz)")
        }

        return result
    }

    /// return a `Settings` instance tha can be used to define configuration values
    /// - Returns: a new `Settings` instance
    //public func settings(file: String = #file, function: String = #function, line: Int = #line) -> Environment.Settings {
    //    return Environment.Settings(configurationManager: self.configurationManager, url: file + " " + function + " line: " + String(line))
    //}

    // MARK: public

    open func configure(_ environment : Environment) throws -> Void {
    }
}

open class EnvironmentBuilder {
    // MARK: local classes

    struct Module {
        var name : String
        var factory : () -> EnvironmentModule

        init(name : String, factory : @escaping () -> EnvironmentModule) {
            self.name = name
            self.factory = factory
        }
    }

   // MARK: instance data

    var name : String
    var traceOrigin = false
    var modules = [String:Module]()

    // MARK: init

    init(name : String, traceOrigin : Bool = false) {
        self.name = name
        self.traceOrigin = traceOrigin
    }

    // MARK: public

    open func register(_ module : String, factory: () -> EnvironmentModule) {
        //if !modules.contains({$0 == module}) {
        //    modules[module] = Module(name: name, factory: factory)
        //}
    }

    // MARK: public

    open func build() throws -> Environment {
        let environment = try Environment(name: name, traceOrigin: traceOrigin)

        return environment
    }
}

class Test {
    class TestModule : EnvironmentModule {
       init() {
           super.init(name: "test")
       }

       override func configure(_ environment : Environment) throws -> Void {
           try environment.define(bean(Test.self, factory: Test.init))
       }
   }

    func foo() {
        let builder = EnvironmentBuilder(name: "test")

        builder.register("test", factory: TestModule.init)

        let environment = try! builder.build()

        print(environment.report())
    }
}
