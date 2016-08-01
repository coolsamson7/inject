//
//  XMLContextLoader.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class XMLContextLoader: XMLParser {
    // local classes
    
    public class Declaration : NSObject, OriginAware {
        // instance data
        
        var _origin : Origin?
        
        // OriginAware
        
        var origin : Origin? {
            get {
                return _origin
            }
            set {
                _origin = newValue
            }
        }
    }
    
    class Beans : Declaration, Ancestor, AttributeContainer {
        // instance data
        
        var declarations : [OriginAware] = []
        
        // Ancestor
        
        func addChild(child : AnyObject) -> Void {
            if let declaration = child as? OriginAware {
                declarations.append(declaration)
            }
        }
        
        // AttributeContainer
        
        subscript(name: String) -> AnyObject {
            get {
                return self // any...
            }
            set {
                // noops
            }
        }
    }
    
    public class Bean : Declaration, Ancestor {
        // instance data
        
        var scope = "singleton"
        var lazy = false
        var abstract = false
        var parent: String? = nil
        var id : String?
        var dependsOn : String?
        var clazz : String?
        var target : String?
        var properties = [Property]()
        
        // init
        
        override init() {
            super.init()
        }
        
        // public
        
        public func convert(context : ApplicationContext) throws -> ApplicationContext.BeanDeclaration {
            let bean = ApplicationContext.BeanDeclaration()
            
            bean.origin = origin
            
            bean.scope = try context.getScope(scope)
            bean.lazy = lazy
            bean.abstract = abstract
            bean.parent = parent != nil ? ApplicationContext.BeanDeclaration(id: parent!) : nil
            bean.id = id
            bean.dependsOn = dependsOn != nil ? ApplicationContext.BeanDeclaration(id: dependsOn!) : nil
            bean.bean = clazz != nil ? try BeanDescriptor.forClass(clazz!) : nil
            bean.target =  target != nil ? try BeanDescriptor.forClass(target!) : nil
            
            
            for property in properties {
                bean.properties.append(try property.convert(context))
            }
            
            return bean
        }
        
        // fluent stuff
        
        func property(property: Property) -> Bean {
            properties.append(property)
            
            return self
        }
        
        
        // Ancestor
        
        func addChild(child : AnyObject) -> Void {
            if let property = child as? Property {
                properties.append(property)
            }
        }
        
        // CustomStringConvertible
        
        override public var description: String {
            let builder = StringBuilder();
            
            builder.append("bean(class: \(clazz)")
            if id != nil {
                builder.append(", id: \"\(id!)\"")
            }
            
            if _origin != nil {
                builder.append(", origin: [\(_origin!.line):\(_origin!.column)]")
            }
            
            builder.append(")")
            
            return builder.toString()
        }
    }
    
    class Property : Declaration, Ancestor {
        // instance data
        
        var name  : String = ""
        var value : AnyObject?
        var ref   : String?
        
        var declaration : Bean?
        
        // public
        
        internal func convert(context : ApplicationContext) throws -> ApplicationContext.PropertyDeclaration {
            let property = ApplicationContext.PropertyDeclaration()
            
            property.origin = origin
            
            property.name = name
            property.value = value
            property.ref = ref != nil ? ApplicationContext.BeanDeclaration(id: ref!): nil
            property.declaration = declaration != nil ? try declaration!.convert(context) : nil
            
            return property
        }
        
        // Node
        
        func addChild(child : AnyObject) -> Void {
            if let bean = child as? Bean {
                declaration = bean
            }
        }
    }
    
    // instance data
    
    var context: ApplicationContext
    
    // init
    
    init(context: ApplicationContext, data : NSData) throws {
        self.context = context
        
        super.init()
        
        try setupParser()
        
        try parse(data)
    }
    
    // public
    /*
    func resolve(string : String) throws -> String {
        var result = string
        
        if let range = string.rangeOfString("${", range: string.startIndex..<string.endIndex) {
            result = string[string.startIndex..<range.startIndex]
            
            let eq  = string.rangeOfString("=", range: range.startIndex..<string.endIndex)
            let end = string.rangeOfString("}", range: range.startIndex..<string.endIndex)
            
            if eq != nil {
                let key = string[range.endIndex ..< eq!.startIndex]
                
                let resolved = try resolver!(key: key)
                
                if (Tracer.ENABLED) {
                    Tracer.trace("loader", level: .HIGH, message: "resolve configuration key \(key) = \(resolved)")
                }
                
                if  resolved != nil {
                    result += resolved!
                }
                else {
                    result += try resolve(string[eq!.endIndex..<end!.startIndex])
                }
            }
            else {
                let key = string[range.endIndex ..< end!.startIndex]
                let resolved = try resolver!(key: key)!
                
                if (Tracer.ENABLED) {
                    Tracer.trace("loader", level: .HIGH, message: "resolve configuration key \(key) = \(resolved)")
                }
                
                result += resolved
            } // else
            
            result += try resolve(string[end!.endIndex..<string.endIndex])
        } // if
        
        return result
    }

    func setup() throws -> Void {
        // local function
        
        func resolveConfiguration(key: String) throws -> String? {
            let fqn = FQN.fromString(key)

            if context.configurationManager.hasValue(fqn.namespace, key: fqn.key) {
                return try context.configurationManager.getValue(String.self, namespace: fqn.namespace, key: fqn.key)
            }
            else {
                return nil
            }
        }
        
        resolver =  resolveConfiguration
        
        if context.parent == nil {
            // add initial bean declarations so that constructed objects can also refer to those instances
            
            try ApplicationContext.BeanDeclaration(instance: context.injector).collect(context, loader: self)
            try ApplicationContext.BeanDeclaration(instance: context.configurationManager).collect(context, loader: self)
            
            context.injector.register(BeanInjection())
            context.injector.register(ConfigurationValueInjection(configurationManager: context.configurationManager))
        }
    }*/
    
    func setupParser() throws -> Void {
        try register(
            ClassDefinition(clazz: Beans.self, element: "beans"),
            
            ClassDefinition(clazz: Bean.self, element: "bean")
                .property("abstract")
                .property("lazy")
                .property("parent")
                .property("scope")
                .property("id")
                .property("dependsOn", xml: "depends-on")
                .property("clazz", xml: "class")
                .property("target"),
            
            ClassDefinition(clazz: Property.self, element: "property")
                .property("name")
                .property("value")
                .property("ref")
        )

        // and all namespace handlers

        for (namespace, handler) in NamespaceHandler.handlers {
            try handler.register(self)
        }
    }
    
    func convert(beans : Beans) throws -> [ApplicationContext.BeanDeclaration] {
        var beanDeclarations : [ApplicationContext.BeanDeclaration] = []
        
        for declaration in beans.declarations {
            if let bean = declaration as? Bean {
                beanDeclarations.append(try bean.convert(self.context))
            }
            else if let namespaceAware = declaration as? NamespaceAware {
                let namespace = namespaceAware.namespace
                
                let handler = NamespaceHandler.byNamespace(namespace!)

                //try handler.register(self)
                
                try handler.process(namespaceAware, beans: &beanDeclarations)
            }
        }
        
        return beanDeclarations
    }
    
    // override
    
    override func parse(data : NSData) throws -> AnyObject? {
        if (Tracer.ENABLED) {
            Tracer.trace("xml loader", level: .HIGH, message: "parse")
        }

        let beans = try super.parse(data) as! Beans

        if (Tracer.ENABLED) {
            Tracer.trace("xml loader", level: .HIGH, message: "process")
        }

        let beanDeclarations = try convert(beans)

        // collect

        for bean in beanDeclarations {
            try context.define(bean)
        }

        return nil
    }
}