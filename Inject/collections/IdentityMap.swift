//
//  IdentityMap.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

open class ObjectIdentityKey: Hashable {
    // MARK: instance data
    
    fileprivate var object: AnyObject
    fileprivate var hash: Int
    
    // init

    public init(object: AnyObject) {
        self.object = object
        self.hash = Unmanaged.passUnretained(object).toOpaque().hashValue
    }
    
    // Hashable
    
    open var hashValue: Int {
        get {
            return hash
        }
    }
}

public func ==(lhs: ObjectIdentityKey, rhs: ObjectIdentityKey) -> Bool {
    return lhs.object === rhs.object
}

open class IdentitySet<T:AnyObject> {
    // MARK: instance data
    
    fileprivate var set = Set<ObjectIdentityKey>()
    
    // MARK: public
    
    open func insert(_ object: T) -> Void {
        set.insert(ObjectIdentityKey(object: object))
    }
    
    open func contains(_ object: T) -> Bool {
        return set.contains(ObjectIdentityKey(object: object))
    }
}

open class IdentityMap<K:AnyObject, V:AnyObject> {
    // MARK: instance data
    
    fileprivate var map = [ObjectIdentityKey: V]()
    
    // MARK: public
    
    subscript(key: K) -> V? {
        get {
            return map[ObjectIdentityKey(object: key)]
        }
        
        set {
            map[ObjectIdentityKey(object: key)] = newValue
        }
    }
}
