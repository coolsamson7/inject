//
//  ConversionErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// All possible errors with respect to conversions

public enum ConversionErrors : Error, CustomStringConvertible {
    case unknownConversion(sourceType: Any.Type, targetType: Any.Type)
    case conversionException(value: Any, targetType: Any.Type, context : String?)

    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .unknownConversion(let sourceType, let targetType):
            builder.append("\(type(of: self)).UnknownConversion: no conversion between \(sourceType) and \(targetType)");
            
        case .conversionException(let value, let targetType, let context):
            builder.append("\(type(of: self)).ConversionException: could not convert \(value) into type \(targetType)");
            if context != nil {
                builder.append("\(context!)")
            }
        } // switch
        
        return builder.toString()
    }
}
