
//
//  Constraints.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation


/// base class for all constraints
open class Constraint<T> {
    // MARK: public

    /// Create a constraint that is the logical and of the specified constraints
    /// Returns: the combined constraint
    open func and(_ constraints : Constraint<T>...) -> Constraint<T> {
        return AndConstraint<T>(constraints: constraints)
    }

    /// Create a constraint that is the logical or of the specified constraints
    /// Returns: the combined constraint
    open func or(_ constraints : Constraint<T>...) -> Constraint<T> {
        return OrConstraint<T>(constraints: constraints)
    }

    /// Create a constraint that is the negation of the specified constraint
    /// Returns: the combined constraint
    open func not(_ constraint : Constraint<T>) -> Constraint<T> {
        return NotConstraint<T>(constraint: constraint)
    }

    // MARK: abstract

    open func eval(_ value : T) -> Bool {
        fatalError("\(type(of: self)).eval is not implemented")
    }
}

/// concatenate two constraints by and
public func &&<T> (left: Constraint<T>, right: Constraint<T>) -> Constraint<T> {
    return left.and(right)
}

/// concatenate two constraints by or
public func ||<T> (left: Constraint<T>, right: Constraint<T>) -> Constraint<T> {
    return left.or(right)
}

// logical constraints

// And operator
class AndConstraint<T> : Constraint<T> {
    // MARK: instance data

    var constraints : [Constraint<T>]

    // MARK: init

    init(constraints : [Constraint<T>]) {
        self.constraints = constraints
    }

    // MARK: implement Constraint

    override func eval(_ value : T) -> Bool {
        for constraint in constraints {
            if !constraint.eval(value) {
                return false
            }
        }

        return true
    }
}

// Or operator
class OrConstraint<T> : Constraint<T> {
    // MARK: instance data

    var constraints : [Constraint<T>]

    // MARK: init

    init(constraints : [Constraint<T>]) {
        self.constraints = constraints
    }

    // MARK: implement Constraint

    override func eval(_ value : T) -> Bool {
        for constraint in constraints {
            if constraint.eval(value) {
                return true
            }
        }

        return false
    }
}

// / Not operator
class NotConstraint<T> : Constraint<T> {
    // MARK: instance data

    var constraint : Constraint<T>

    // MARK: init

    init(constraint : Constraint<T>) {
        self.constraint = constraint
    }

    // MARK: implement Constraint

    override func eval(_ value : T) -> Bool {
        return !constraint.eval(value)
    }
}

/// constraint based on closure
open class ClosureConstraint<T> : Constraint<T> {
    // MARK: instance data

    var closure : (T) -> Bool

    // MARK: init

    init(closure: @escaping (T) -> Bool) {
        self.closure = closure
    }

    // MARK: override Constraint

    open override func eval(_ value : T) -> Bool {
        return closure(value)
    }
}

// We may need to change to real classes if we need additional behaviour, e.g. localizations, automatic data binding...
/*public class Greater<T : Comparable> : Constraint<T> {
   // MARK: instance data

    var value : T

    // MARK: init

    public init(value : T) {
        self.value = value
    }

    // MARK: override Constraint

    public override func eval(object : T) -> Bool {
        return object > value
    }
}*/
