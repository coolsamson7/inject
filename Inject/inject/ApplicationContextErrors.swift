//
//  ApplicationContextErrors.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public enum ApplicationContextErrors: ErrorType , CustomStringConvertible {
    case ParseError(message: String)
    case NoCandidateForType(type : Any.Type)
    case AmbiguousCandidatesForType(type : Any.Type)
    case UnknownBeanByType(type : AnyClass)
    case AmbiguousBeanByType(type : AnyClass)
    case AmbiguousBeanById(id : String, context: String)
    case UnknownBeanById(id : String, context: String)
    case UnknownProperty(property:String, bean : Environment.BeanDeclaration)
    case CylicDependencies(message:String)
    case UnknownScope(scope : String, context: String)
    case TypeMismatch(message: String)
    case Exception(message: String)
    
    // CustomStringConvertible
    
    public var description: String {
        let builder = StringBuilder();
        
        switch self {
        case .ParseError(let message):
            builder.append("\(self.dynamicType).ParseError: \(message)");
            
        case .NoCandidateForType(let type):
            builder.append("\(self.dynamicType).NoCandidateForType: no matching candidate for type \(type)");
            
        case .AmbiguousCandidatesForType(let type):
            builder.append("\(self.dynamicType).AmbiguousCandidatesForType: ambiguous candidates for type \(type)");
            
        case .AmbiguousBeanByType(let type):
            builder.append("\(self.dynamicType).AmbiguousBeanByType: ambiguous bean by type \(type)");
            
        case .AmbiguousBeanById(let id, _):
            builder.append("\(self.dynamicType).AmbiguousBeanById: ambiguous bean by id \(id)");
            
        case .UnknownBeanByType(let type):
            builder.append("\(self.dynamicType).UnknownBeanByType: no bean by type \(type)");
            
        case .UnknownBeanById(let id, let context):
            builder.append("\(self.dynamicType).UnknownBeanRef: no bean with id \(id) in \(context)");
            
        case .CylicDependencies(let message):
            builder.append("\(self.dynamicType).CylicDependencies: \(message)");
            
        case .UnknownProperty(let property, let bean):
            builder.append("\(self.dynamicType).UnknownProperty: \(bean.bean).\(property)")
            if bean.origin != nil {
                builder.append(" in [\(bean.origin!.line):\(bean.origin!.column)]")
            }
            
        case .TypeMismatch(let message):
            builder.append("\(self.dynamicType).TypeMismatch: \(message)");
            
        case .UnknownScope(let scope):
            builder.append("\(self.dynamicType).UnknownScope: unknown scope \"\(scope)\"");

            case .Exception(let message):
                builder.append("\(self.dynamicType).Exception: \"\(message)\"");
        } // switch
        
        return builder.toString()
    }
}
