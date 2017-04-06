//
//  XMLParserErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public enum XMLParserErrors : Error, CustomStringConvertible {
    case parseException(message: String)
    case validationException(message: String)
    case exception(message: String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .parseException(let message):
            builder.append("\(type(of: self)).ParseException: ").append(message);
        case .validationException(let message):
            builder.append("\(type(of: self)).ValidationException: ").append(message);
        case .exception(let message):
            builder.append("\(type(of: self)).Exception: ").append(message);
        } // switch
        
        return builder.toString()
    }
}
