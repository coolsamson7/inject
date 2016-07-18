//
//  BeanScope.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

protocol BeanScope {
    var name : String {
        get
    }
    
    func prepare(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws
    
    func get(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws -> AnyObject
    
    func finish()
}

// TODO

public class PrototypeScope : BeanScope {
    // Scope
    
    var name : String {
        get {
            return "prototype"
        }
    }
    
    func prepare(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws {
        // noop
    }
    
    func get(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
        return try factory.create(bean)
    }
    
    func finish() {
        // noop
    }
}

public class SingletonScope : BeanScope {
    // Scope
    
    var name : String {
        get {
            return "singleton"
        }
    }
    
    func prepare(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws {
        if !bean.lazy {
            try get(bean, factory: factory)
        }
    }
    
    func get(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
        if bean.singleton == nil {
            bean.singleton = try factory.create(bean)
        }
        
        return bean.singleton!
    }
    
    func finish() {
        // noop
    }
}