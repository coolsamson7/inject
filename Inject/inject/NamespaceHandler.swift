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
    var context : ApplicationContext? = nil

    // init
    
    init(namespace : String) {
        self.namespace = namespace

        NamespaceHandler.handlers[namespace] = self
    }
    
    // fluent stuff

    func scope(scope : String) throws -> BeanScope {
        return try context!.getScope(scope)
    }
    
    public func beanDeclaration(instance : AnyObject, id : String? = nil, scope :  String = "singleton") throws -> ApplicationContext.BeanDeclaration {
        let result = ApplicationContext.BeanDeclaration(instance: instance)
        
        if id != nil {
            result.id = id
        }
        
        result.scope = try self.scope(scope)
        
        return result
    }
    
    public func beanDeclaration(clazz : String, id : String? = nil) throws -> ApplicationContext.BeanDeclaration {
        let result = ApplicationContext.BeanDeclaration()
        
        if id != nil {
            result.id = id
        }
        
        result.bean = try BeanDescriptor.forClass(clazz)
        
        return result
    }
    
    public func property(name: String? = nil) ->  ApplicationContext.PropertyDeclaration {
        let result =  ApplicationContext.PropertyDeclaration()
        
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
    
    func register(loader : XMLContextLoader) throws {
        self.context = loader.context
    }
    
    func process(namespaceAware : NamespaceAware, inout beans : [ApplicationContext.BeanDeclaration]) throws -> Void {
    }
}