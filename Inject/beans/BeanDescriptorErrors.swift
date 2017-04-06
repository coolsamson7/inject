
//
//  BeanDescriptorErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// All errors concerning aspects of the class `BeanDescriptor`
public enum BeanDescriptorErrors : Error , CustomStringConvertible {
    case unknownProperty(message:String)
    case cannotSetNil(message: String)
    case typeMismatch(message: String)
    case exception(message: String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .unknownProperty(let message):
            builder.append("\(type(of: self)).UnknownProperty: ").append(message)

        case .cannotSetNil(let message):
            builder.append("\(type(of: self)).CannotSetNil: ").append(message)

        case .typeMismatch(let message):
            builder.append("\(type(of: self)).TypeMismatch: ").append(message)

        case .exception(let message):
                builder.append("\(type(of: self)).Exception: ").append(message)
        } // switch
        
        return builder.toString()
    }
}
