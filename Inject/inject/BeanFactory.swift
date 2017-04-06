//
//  BeanFactory.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A BeanFactory is responsible to create an instance given a BeanDeclaration
public protocol BeanFactory {
    /// create a new instance
    /// - Parameter bean: the corresponding `BeanDeclaration`
    /// - Returns: the new instance
    /// Throws: any error during construction
    func create(_ bean : Environment.BeanDeclaration) throws -> AnyObject
}
