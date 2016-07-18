
//
//  BeanDescriptorErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

public enum BeanDescriptorErrors : ErrorType , CustomStringConvertible {
    case UnknownProperty(message:String)
    case CannotSetNil(message: String)
    case TypeMismatch(message: String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .UnknownProperty(let message):
            builder.append("\(self.dynamicType).UnknownProperty: ").append(message);
        case .CannotSetNil(let message):
            builder.append("\(self.dynamicType).CannotSetNil: ").append(message);
        case .TypeMismatch(let message):
            builder.append("\(self.dynamicType).TypeMismatch: ").append(message);
        } // switch
        
        return builder.toString()
    }
}