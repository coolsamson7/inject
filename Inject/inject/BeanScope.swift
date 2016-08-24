//
//  BeanScope.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `BeanScope` controls the lifecycle of a bean.
public protocol BeanScope {
    /// the name of the scope
    var name : String {
        get
    }

    /// prepare a bean declaration of an environment after validation
    /// specific implementing classes may use this callback to create instacnes on demand
    /// - Parameter bean: the `BeanDeclaration`
    /// - Parameter factory: the factory that cerates an instance
    func prepare(bean : Environment.BeanDeclaration, factory : BeanFactory) throws

    /// return a new or possibly cached instance given the bean declaration
    /// - Parameter bean: the `BeanDeclaration`
    /// - Parameter factory: the factory that cerates an instance
    func get(bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject

    /// execute any cleanup code after a scope has ended. ( e.g. after session removal )
    func finish()
}

public class AbstractBeanScope : NSObject, BeanScope, EnvironmentAware {
    // MARK: instance data

    var _name : String

    public var name : String {
        get {
            return _name
        }
    }

    var environment: Environment? {
        get {
            return nil
        }
        set {
            newValue!.registerScope(self)
        }
    }

    // MARK: init

    override init() {
        _name = ""
        super.init()
    }

    init(name : String) {
        self._name = name
    }

    // MARK: implement BeanScope

    public func prepare(bean : Environment.BeanDeclaration, factory : BeanFactory) throws {
    }

    public func get(bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
        fatalError("\(self.dynamicType).get not implemented ")
    }

    public func finish() {
        // noop
    }
}