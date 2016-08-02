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
        var value : String?
        var ref   : String?
        
        var declaration : Bean?
        
        // public
        
        internal func convert(context : ApplicationContext) throws -> ApplicationContext.PropertyDeclaration {
            let property = ApplicationContext.PropertyDeclaration()
            
            property.origin = origin
            
            property.name = name
            if ref != nil {
                property.value = ApplicationContext.BeanReference(ref: ref!)
            }
            else if declaration != nil {
                property.value = ApplicationContext.EmbeddedBean(bean: try declaration!.convert(context))
            }
            else {
                property.value = ApplicationContext.PlaceHolder(value: value!)
            }


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