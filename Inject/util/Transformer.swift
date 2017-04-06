//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

open class Property<C> : CustomStringConvertible {
    // MARK: abstract

    func get(_ object: AnyObject!, context: C) throws -> Any? {
        fatalError("\(type(of: self)).get is not implemented")
    }

    func set(_ object: AnyObject!, value: Any?, context: C) throws -> Void {
        fatalError("\(type(of: self)).set is not implemented")
    }

    // MARK: implement CustomStringConvertible

    open var description : String {
        return "\(type(of: self))"
    }
}

open class Operation<C> : CustomStringConvertible {
    // instance data

    var source: Property<C>
    var target: Property<C>

    // init

    public init(source: Property<C>, target: Property<C>) {
        self.source = source
        self.target = target
    }

    // methods

    func setTarget(_ from: AnyObject, to: AnyObject, context: C) throws -> Void {
        try target.set(to, value: source.get(from, context: context), context: context)
    }

    func setSource(_ to: AnyObject, from: AnyObject, context: C) throws -> Void {
        try source.set(from, value: target.get(to, context: context), context: context)
    }

    // MARK: implement CustomStringConvertible

    open var description : String {
        return "Operation[source: \(source), target: \(target)]"
    }
}

open class XFormer<C> {
    // MARK: instance data

    var operations: [Operation<C>]

    // MARK: init

    public init(operations: [Operation<C>]) {
        self.operations = operations
    }

    // MARK: public

    open func xformTarget(_ source: AnyObject, target: AnyObject, context: C) throws -> Void {
        for operation in operations {
            try operation.setTarget(source, to: target, context: context)
        }
    }

    open func xformSource(_ target: AnyObject, source: AnyObject, context: C) throws -> Void {
        for operation in operations {
            try operation.setSource(target, from: source, context: context)
        }
    }
}

open class BeanProperty<C> : Property<C> {
    // MARK: instance data

    var property: BeanDescriptor.PropertyDescriptor

    // MARK: init

    public init(property: BeanDescriptor.PropertyDescriptor) {
        self.property = property
    }

    // MARK: override Property

    override func get(_ object: AnyObject!, context: C) throws -> Any? {
        if (Tracer.ENABLED) {
            Tracer.trace("beans", level: .high, message: "get property \"\(property.name)\"")
        }

        return property.get(object)
    }

    override func set(_ object: AnyObject!, value: Any?, context: C) throws -> Void {
        if (Tracer.ENABLED) {
            Tracer.trace("beans", level: .high, message: "set property \"\(property.name)\" to \(String(describing: value))")
        }

        try property.set(object, value: value)
    }

    // MARK: implement CustomStringConvertible

    override open var description: String {
        get {
            return "\(property)"
        }
    }
}
