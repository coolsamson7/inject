//
//  EnvironmentModule.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

// NEW

public protocol EnvironmentModule: Initializable {
    func require<T :EnvironmentModule>(_ module : T.Type) throws -> Void;

    func finish() -> Void ;

    func configure(_ environment : Environment) throws -> Void;
}

public class EnvironmentBuilder {
    // local classes
    
    public class Module: EnvironmentModule {
        // instance data

        var name : String = "";
        var loaded = false;
        var builder : EnvironmentBuilder? = nil;

        // init
        
        public init(name : String) {
            self.name = name;
        }

        public required init() {
        }

        // more

        func config(builder : EnvironmentBuilder) throws {
            self.builder = builder;

            try configure(builder.currentEnvironment!)
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

            //if traceOrigin {
            //    result.origin = Origin(file: file, line: line, column: column)
            //}

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

            //if traceOrigin {
            //    result.origin = Origin(file: file, line: line, column: column)
            //}

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

            //if traceOrigin {
            //    result.origin = Origin(file: file, line: line, column: column)
            //}

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

        // implement Module

        open func configure(_ environment : Environment) throws -> Void {
            // noop
        }

        open func finish() -> Void {
            builder!.finish();
        }

        open func require<T :EnvironmentModule>(_ module : T.Type) throws -> Void {
            try builder!.require(module);
        }
    }

    // instance data

    var currentEnvironment : Environment?;
    var modules : Environment?; // the internal environment for modules...

    // init

    init(name : String = "environment") {
        currentEnvironment = try! Environment(name: name, parent: nil);
        modules =  try! Environment(name: "modules", parent: nil);
    }

    // private

    func finish() {
        currentEnvironment = try! Environment(name: "next environemnt", parent: currentEnvironment); // TODO
    }

    func require<T :EnvironmentModule>(_ type :  T.Type) throws -> Void {
        let module = try modules!.getBean(type)

        try buildModule(module: module as! EnvironmentModule)
    }

    func environment() throws -> Environment {
        return currentEnvironment!
    }

    func buildModule(module : EnvironmentModule) throws -> Void {
        if let mod = module as? Module {
            if !mod.loaded {
                // mark as loaded

                mod.loaded = true;

                // go

                mod.builder = self;

                try mod.configure(currentEnvironment!);
            }
        }
    }

    // public

    public func register(module : EnvironmentModule) throws -> Void {
        try modules!.define(modules!.bean(module))
    }

    public func register<T :EnvironmentModule>(type :  T.Type) throws -> Void {
        try modules!.define(modules!.bean(type))
    }

    public func build(module : EnvironmentModule) throws -> Environment {
        try buildModule(module: module);

        // done

        return try currentEnvironment!.startup()
    }

    public func build<T :EnvironmentModule>(module :  T.Type) throws -> Environment {
        try buildModule(module: modules!.getBean(module))

        // done

        return try currentEnvironment!.startup()
    }
}
