//
//  XMLParserErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public enum XMLParserErrors : ErrorType, CustomStringConvertible {
    case ParseException(message: String)
    case ValidationException(message: String)
    case Exception(message: String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .ParseException(let message):
            builder.append("\(self.dynamicType).ParseException: ").append(message);
        case .ValidationException(let message):
            builder.append("\(self.dynamicType).ValidationException: ").append(message);
        case .Exception(let message):
            builder.append("\(self.dynamicType).Exception: ").append(message);
        } // switch
        
        return builder.toString()
    }
}