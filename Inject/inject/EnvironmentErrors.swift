//
//  EnvironmentErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

// all possible errors in the context of an environment
public enum EnvironmentErrors: Error , CustomStringConvertible {
    case parseError(message: String)
    case noCandidateForType(type : Any.Type)
    case ambiguousCandidatesForType(type : Any.Type)
    case unknownBeanByType(type : Any.Type)
    case ambiguousBeanByType(type : Any.Type)
    case ambiguousBeanById(id : String, context: String)
    case unknownBeanById(id : String, context: String)
    case unknownProperty(property:String, bean : Environment.BeanDeclaration)
    case cylicDependencies(message:String)
    case unknownScope(scope : String, context: String)
    case typeMismatch(message: String)
    case exception(message: String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .parseError(let message):
            builder.append("\(type(of: self)).ParseError: \(message)");
            
        case .noCandidateForType(let type):
            builder.append("\(type(of: self)).NoCandidateForType: no matching candidate for type \(type)");
            
        case .ambiguousCandidatesForType(let type):
            builder.append("\(type(of: self)).AmbiguousCandidatesForType: ambiguous candidates for type \(type)");
            
        case .ambiguousBeanByType(let type):
            builder.append("\(type(of: self)).AmbiguousBeanByType: ambiguous bean by type \(type)");
            
        case .ambiguousBeanById(let id, _):
            builder.append("\(type(of: self)).AmbiguousBeanById: ambiguous bean by id \(id)");
            
        case .unknownBeanByType(let type):
            builder.append("\(type(of: self)).UnknownBeanByType: no bean by type \(type)");
            
        case .unknownBeanById(let id, let context):
            builder.append("\(type(of: self)).UnknownBeanRef: no bean with id \(id) in \(context)");
            
        case .cylicDependencies(let message):
            builder.append("\(type(of: self)).CylicDependencies: \(message)");
            
        case .unknownProperty(let property, let bean):
            builder.append("\(type(of: self)).UnknownProperty: \(bean.clazz!).\(property)")
            if bean.origin != nil {
                builder.append(" in [\(bean.origin!.line):\(bean.origin!.column)]")
            }
            
        case .typeMismatch(let message):
            builder.append("\(type(of: self)).TypeMismatch: \(message)");
            
        case .unknownScope(let scope):
            builder.append("\(type(of: self)).UnknownScope: unknown scope \"\(scope)\"");

            case .exception(let message):
                builder.append("\(type(of: self)).Exception: \"\(message)\"");
        } // switch
        
        return builder.toString()
    }
}
