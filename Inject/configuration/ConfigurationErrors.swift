//
//  ConfigurationErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public enum ConfigurationErrors : Error , CustomStringConvertible {
    case parseError(message:String)
    case exception(message:String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .parseError(let type):
            builder.append("\(type(of: self)).ParseError: \(type)");
        case .exception(let message):
            builder.append("\(type(of: self)).Exception: \(message)");
        } // switch
        
        return builder.toString()
    }
}
