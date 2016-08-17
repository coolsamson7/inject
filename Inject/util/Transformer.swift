//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class Property<C> : CustomStringConvertible {
    // MARK: abstract

    func get(object: AnyObject!, context: C) throws -> Any? {
        fatalError("\(self.dynamicType).get is not implemented")
    }

    func set(object: AnyObject!, value: Any?, context: C) throws -> Void {
        fatalError("\(self.dynamicType).set is not implemented")
    }

    // MARK: implement CustomStringConvertible

    public var description : String {
        return "\(self.dynamicType)"
    }
}

public class Operation<C> : CustomStringConvertible {
    // instance data

    var source: Property<C>
    var target: Property<C>

    // init

    init(source: Property<C>, target: Property<C>) {
        self.source = source
        self.target = target
    }

    // methods

    func setTarget(from: AnyObject, to: AnyObject, context: C) throws -> Void {
        try target.set(to, value: source.get(from, context: context), context: context)
    }

    func setSource(to: AnyObject, from: AnyObject, context: C) throws -> Void {
        try source.set(from, value: target.get(to, context: context), context: context)
    }

    // MARK: implement CustomStringConvertible

    public var description : String {
        return "Operation[source: \(source), target: \(target)]"
    }
}

public class XFormer<C> {
    // MARK: instance data

    var operations: [Operation<C>]

    // MARK: init

    init(operations: [Operation<C>]) {
        self.operations = operations
    }

    // MARK: public

    public func xformTarget(source: AnyObject, target: AnyObject, context: C) throws -> Void {
        for operation in operations {
            try operation.setTarget(source, to: target, context: context)
        }
    }

    public func xformSource(target: AnyObject, source: AnyObject, context: C) throws -> Void {
        for operation in operations {
            try operation.setSource(target, from: source, context: context)
        }
    }
}

public class BeanProperty<C> : Property<C> {
    // MARK: instance data

    var property: BeanDescriptor.PropertyDescriptor

    // MARK: init

    init(property: BeanDescriptor.PropertyDescriptor) {
        self.property = property
    }

    // MARK: override Property

    override func get(object: AnyObject!, context: C) throws -> Any? {
        if (Tracer.ENABLED) {
            Tracer.trace("beans", level: .HIGH, message: "get property \"\(property.name)\"")
        }

        return property.get(object)
    }

    override func set(object: AnyObject!, value: Any?, context: C) throws -> Void {
        if (Tracer.ENABLED) {
            Tracer.trace("beans", level: .HIGH, message: "set property \"\(property.name)\" to \(value)")
        }

        try property.set(object, value: value)
    }

    // MARK: implement CustomStringConvertible

    override public var description: String {
        get {
            return "\(property)"
        }
    }
}