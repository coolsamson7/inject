//
//  ThreadLocal.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class ThreadLocal<T> {
    // MARK: types
    
    typealias Generator = () -> T
    
    // MARK: instance data
    
    var id : String
    var generator : Generator;
    
    // MARK: constructor
    
    init(generator : Generator) {
        self.generator = generator
        self.id =  NSUUID().UUIDString
    }
    
    // MARK: public
    
    public func get() -> T {
        let threadDictionary = NSThread.currentThread().threadDictionary;
        
        if let cachedObject = threadDictionary[id] as? T {
            return cachedObject
        }
        else {
            let value = generator()
            
            threadDictionary[id] = value as? AnyObject
            
            return value
        }
    }
    
    public func set(value : T) -> Void {
        NSThread.currentThread().threadDictionary[id] = value as? AnyObject
    }
    
    public func remove() -> Void {
        NSThread.currentThread().threadDictionary.removeObjectForKey(id)
    }
}