
//
//  BeanDescriptorInitializer.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// this protocol defines a callback function that will be invoked by the bean descriptor whenever it analyzes an object of this type.
public protocol BeanDescriptorInitializer {
    /// implement any code to add information to the bean descriptor
    func initializeBeanDescriptor(descriptor : BeanDescriptor) -> Void
}
