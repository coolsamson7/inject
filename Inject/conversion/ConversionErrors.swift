//
//  ConversionErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// All possible errors with respect to conversions

public enum ConversionErrors : ErrorType, CustomStringConvertible {
    case UnknownConversion(sourceType: Any.Type, targetType: Any.Type)
    case ConversionException(value: Any, targetType: Any.Type, context : String?)

    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .UnknownConversion(let sourceType, let targetType):
            builder.append("\(self.dynamicType).UnknownConversion: no conversion between \(sourceType) and \(targetType)");
            
        case .ConversionException(let value, let targetType, let context):
            builder.append("\(self.dynamicType).ConversionException: could not convert \(value) into type \(targetType)");
            if context != nil {
                builder.append("\(context!)")
            }
        } // switch
        
        return builder.toString()
    }
}