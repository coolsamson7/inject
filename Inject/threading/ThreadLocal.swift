//
//  ThreadLocal.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// a thread local for the specified dgeneric type
open class ThreadLocal<T> {
    // MARK: types

    /// a generator function for initial values
    public typealias Generator = () -> T
    
    // MARK: instance data
    
    var id : String
    var generator : Generator;
    
    // MARK: constructor

    // Create a new `ThreadLocal` given a generator for inital values
    /// - Parameter generator : the generator
    public init(generator : @escaping Generator) {
        self.generator = generator
        self.id =  UUID().uuidString
    }
    
    // MARK: public

    /// Return the thread local value associated to the current thread. If no value is set, the generator will be called
    /// Returns: the associated value
    open func get() -> T {
        let threadDictionary = Thread.current.threadDictionary;
        
        if let cachedObject = threadDictionary[id] as? T {
            return cachedObject
        }
        else {
            let value = generator()
            
            threadDictionary[id] = value as AnyObject
            
            return value
        }
    }

    /// Set the thread lcoal to the specified value
    /// - Parameter value: the new value
    open func set(_ value : T) -> Void {
        Thread.current.threadDictionary[id] = value as AnyObject
    }

    /// remove any associated thread local
    open func remove() -> Void {
        Thread.current.threadDictionary.removeObject(forKey: id)
    }
}
