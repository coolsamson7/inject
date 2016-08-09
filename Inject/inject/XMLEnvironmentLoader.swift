//
//  XMLEnvironmentLoader.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class XMLEnvironmentLoader: XMLParser {
    // local classes
    
    public class Declaration : NSObject, OriginAware {
        // MARK: instance data
        
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
        // MARK: instance data
        
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
        // MARK: instance data
        
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
        
        // MARK: public
        
        public func convert(environment: Environment) throws -> Environment.BeanDeclaration {
            let bean = Environment.BeanDeclaration()
            
            bean.origin = origin
            
            bean.scope = try environment.getScope(scope)
            bean.lazy = lazy
            bean.abstract = abstract
            bean.parent = parent != nil ? Environment.BeanDeclaration(id: parent!) : nil
            bean.id = id
            bean.dependsOn = dependsOn != nil ? Environment.BeanDeclaration(id: dependsOn!) : nil
            bean.bean = clazz != nil ? try BeanDescriptor.forClass(clazz!) : nil
            bean.target =  target != nil ? try BeanDescriptor.forClass(target!) : nil
            
            
            for property in properties {
                bean.properties.append(try property.convert(environment))
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
        // MARK: instance data
        
        var name  : String = ""
        var value : String?
        var ref   : String?
        
        var declaration : Bean?
        
        // MARK: public
        
        internal func convert(environment: Environment) throws -> Environment.PropertyDeclaration {
            let property = Environment.PropertyDeclaration()
            
            property.origin = origin
            
            property.name = name
            if ref != nil {
                property.value = Environment.BeanReference(ref: ref!)
            }
            else if declaration != nil {
                property.value = Environment.EmbeddedBean(bean: try declaration!.convert(environment))
            }
            else {
                property.value = Environment.PlaceHolder(value: value!)
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
    
    // MARK: instance data
    
    var environment: Environment
    
    // init
    
    init(environment: Environment) throws {
        self.environment = environment
        
        super.init()
        
        try setupParser()
    }
    
    // MARK: public
    
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

        for (_, handler) in NamespaceHandler.handlers {
            try handler.register(self)
        }
    }
    
    // override
    
    override func parse(data : NSData) throws -> AnyObject? {
        if (Tracer.ENABLED) {
            Tracer.trace("inject.xml", level: .HIGH, message: "parse")
        }

        let beans = try super.parse(data) as! Beans

        if (Tracer.ENABLED) {
            Tracer.trace("inject.xml", level: .HIGH, message: "process")
        }

        for declaration in beans.declarations {
            if let bean = declaration as? Bean {
                try environment.define(try bean.convert(self.environment))
            }
            else if let namespaceAware = declaration as? NamespaceAware {
                try NamespaceHandler.byNamespace(namespaceAware.namespace!).process(namespaceAware, environment: environment)
            }
        }


        return nil
    }
}