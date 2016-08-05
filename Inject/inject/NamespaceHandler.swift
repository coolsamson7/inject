//
//  NamespaceHandler.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class NamespaceHandler {
    // static data

    static var handlers = [String:NamespaceHandler]()

    // class func name

    class func byNamespace(namespace : String) -> NamespaceHandler {
        let handler = NamespaceHandler.handlers[namespace]

        if handler != nil {
            return handler!
        }
        else {
            fatalError("no namespace hander for \(namespace)")
        }
    }

    // instance data
    
    var namespace : String
    var environment: Environment? = nil

    // init
    
    init(namespace : String) {
        self.namespace = namespace

        NamespaceHandler.handlers[namespace] = self
    }
    
    // fluent stuff

    func scope(scope : String) throws -> BeanScope {
        return try environment!.getScope(scope)
    }
    
    public func beanDeclaration(instance : AnyObject, id : String? = nil, scope :  String = "singleton") throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration(instance: instance)
        
        if id != nil {
            result.id = id
        }
        
        result.scope = try self.scope(scope)
        
        return result
    }
    
    public func beanDeclaration(clazz : String, id : String? = nil) throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration()
        
        if id != nil {
            result.id = id
        }
        
        result.bean = try BeanDescriptor.forClass(clazz)
        
        return result
    }
    
    public func property(name: String? = nil) ->  Environment.PropertyDeclaration {
        let result =  Environment.PropertyDeclaration()
        
        if name != nil {
            result.name = name!
        }
        
        return result
    }
    
    // fluent parser stuff
    
    public func mapping(clazz: AnyClass, element: String) -> XMLParser.ClassDefinition {
        let result = XMLParser.ClassDefinition(clazz: clazz, element: element)
        
        return result
    }
    
    // abstract
    
    func register(loader : XMLEnvironmentLoader) throws {
        self.environment = loader.environment
    }
    
    func process(namespaceAware : NamespaceAware, environment : Environment) throws -> Void {
    }
}