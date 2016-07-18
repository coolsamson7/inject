//
//  IdentityMap.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class ObjectIdentityKey: Hashable {
    // instance data
    
    private var object: AnyObject
    private var hash: Int;
    
    // init
    
    init(object: AnyObject) {
        self.object = object;
        self.hash = unsafeAddressOf(object).hashValue;
    }
    
    // Hashable
    
    public var hashValue: Int {
        get {
            return hash
        }
    }
}

public func ==(lhs: ObjectIdentityKey, rhs: ObjectIdentityKey) -> Bool {
    return lhs.object === rhs.object;
}

public class IdentitySet<T:AnyObject> {
    // local classes
    // instance data
    
    private var set = Set<ObjectIdentityKey>();
    
    // public
    
    public func insert(object: T) -> Void {
        set.insert(ObjectIdentityKey(object: object))
    }
    
    public func contains(object: T) -> Bool {
        return set.contains(ObjectIdentityKey(object: object))
    }
}

public class IdentityMap<K:AnyObject, V:AnyObject> {
    // instance data
    
    private var map = [ObjectIdentityKey: V]();
    
    // public
    
    subscript(key: K) -> V? {
        get {
            return map[ObjectIdentityKey(object: key)]
        }
        
        set {
            map[ObjectIdentityKey(object: key)] = newValue
        }
    }
}
