//
//  ConfigurationErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public enum ConfigurationErrors : ErrorType , CustomStringConvertible {
    case ParseError(message:String)
    case Exception(message:String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .ParseError(let type):
            builder.append("\(self.dynamicType).ParseError: \(type)");
        case .Exception(let message):
            builder.append("\(self.dynamicType).Exception: \(message)");
        } // switch
        
        return builder.toString()
    }
}