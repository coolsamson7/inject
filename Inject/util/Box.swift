//
//  Box.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

final public class Box<T> {
    // MARK: instance data
    
    public var value: T
    
    // init
    
    public init(_ value: T) {
        self.value = value
    }
}