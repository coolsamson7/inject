//
//  Box.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

final public class Box<T> {
    // instance data
    
    public var value: T
    
    // init
    
    init(_ value: T) {
        self.value = value
    }
}