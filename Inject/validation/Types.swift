
//
//  Types.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// non generic base class for types
open class TypeDescriptor {
    // MARK: instance data
    
    var type : Any.Type

    // MARK: init
    
    init(type : Any.Type) {
        self.type = type
    }
    
    // MARK: public
    
    /// Return the underlying type
    /// Returns: the base type
    open func getType() -> Any.Type {
        return type
    }
    
    /// Return `true` if the argument is value, `false` otherwise
    /// Returns: the valid state
    open func isValid(_ value : Any) -> Bool {
        return  true
    }
}

/// generic base class for all types
open class GenericTypeDescriptor<T> : TypeDescriptor {
    // MARK: instance data

    var constraint : Constraint<T>
    
    // MARK: init

    public init(constraint : Constraint<T>) {
        self.constraint = constraint
        
        super.init(type: T.self)
    }

    // MARK: override TypeDesriptor


    /// Return `true` if the argument is value, `false` otherwise
    /// Returns: the valid state
    override open func isValid(_ object : Any) -> Bool {
        return constraint.eval(object as! T)
    }
}

// typedescriptor for `Equatable`s
open class EquatableTypeDescriptor<T : Equatable> : GenericTypeDescriptor<T> {
    // MARK: convenience functions

    open class func equal<T : Equatable>(_ value : T) -> Constraint<T>  {
        return ClosureConstraint<T>(closure: {$0 == value})
    }

    open class func nonEqual<T : Equatable>(_ value : T) -> Constraint<T>  {
        return ClosureConstraint<T>(closure: {$0 != value})
    }

    // MARK: init

    public override init(constraint : Constraint<T>) {
        super.init(constraint: constraint)
    }
}

// typedescriptor for `Comparable`s
open class ComparableTypeDescriptor<T : Comparable> : EquatableTypeDescriptor<T> {
    // MARK: convenience functions

    open class func lessEqual<T : Comparable>(_ value : T) -> Constraint<T>  {
        return ClosureConstraint<T>(closure: {$0 <= value})
    }

    open class func less<T : Comparable>(_ value : T) -> Constraint<T>  {
        return ClosureConstraint<T>(closure: {$0 < value})
    }

    open class func greaterEqual<C : Comparable>(_ value : C) -> Constraint<C>  {
        return ClosureConstraint<C>(closure: {$0 >= value})
    }

    open class func greater<T : Comparable>(_ value : T) -> Constraint<T>  {
        return ClosureConstraint<T>(closure: {$0 > value})
    }

    // MARK: init

    public override init(constraint : Constraint<T>) {
        super.init(constraint: constraint)
    }
}

// numeric

open class NumericTypeDescriptor<T : Comparable> : ComparableTypeDescriptor<T> {
    // MARK: init

    public override init(constraint : Constraint<T>) {
        super.init(constraint: constraint)
    }
}

// string

open class StringTypeDescriptor : ComparableTypeDescriptor<String> {
    // MARK: convenience functions

    open class func length(_ max : Int) -> Constraint<String> {
        return ClosureConstraint<String>(closure: {$0.characters.count <= max})
    }

    // MARK: init

    public override init(constraint : Constraint<String>) {
        super.init(constraint: constraint)
    }
}
