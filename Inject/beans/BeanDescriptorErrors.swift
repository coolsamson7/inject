
//
//  BeanDescriptorErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// All errors concerning aspects of the class `BeanDescriptor`
public enum BeanDescriptorErrors : ErrorType , CustomStringConvertible {
    case UnknownProperty(message:String)
    case CannotSetNil(message: String)
    case TypeMismatch(message: String)
    case Exception(message: String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .UnknownProperty(let message):
            builder.append("\(self.dynamicType).UnknownProperty: ").append(message)

        case .CannotSetNil(let message):
            builder.append("\(self.dynamicType).CannotSetNil: ").append(message)

        case .TypeMismatch(let message):
            builder.append("\(self.dynamicType).TypeMismatch: ").append(message)

        case .Exception(let message):
                builder.append("\(self.dynamicType).Exception: ").append(message)
        } // switch
        
        return builder.toString()
    }
}