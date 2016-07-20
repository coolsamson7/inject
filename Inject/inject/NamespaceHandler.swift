//
//  NamespaceHandler.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class NamespaceHandler {
    // instance data
    
    var namespace : String
    
    // init
    
    init(namespace : String) {
        self.namespace = namespace
    }
    
    // fluent stuff
    
    public func beanDeclaration(instance : AnyObject, id : String? = nil) -> ApplicationContext.BeanDeclaration {
        let result = ApplicationContext.BeanDeclaration(instance: instance)
        
        if id != nil {
            result.id = id
        }
        
        result.scope = nil // todo
        result.singleton = instance
        
        return result
    }
    
    public func beanDeclaration(clazz : String, id : String? = nil) -> ApplicationContext.BeanDeclaration {
        let result = ApplicationContext.BeanDeclaration()
        
        if id != nil {
            result.id = id
        }
        
        result.bean = BeanDescriptor.forClass(clazz)
        
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
    
    func register(parser : ApplicationContextLoader) throws {
        // noop
    }
    
    func process(namespaceAware : NamespaceAware, inout beans : [ApplicationContext.BeanDeclaration]) throws -> Void {
    }
}