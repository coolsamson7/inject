//
//  ApplicationContextLoader.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public typealias Resolver = (key : String) throws -> String?

public class ApplicationContextLoader: XMLParser {
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
        
        var declarations : [Declaration] = []
        
        // Ancestor
        
        func addChild(child : AnyObject) -> Void {
            if let declaration = child as? Declaration {
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
            bean.clazz = clazz != nil ? BeanDescriptor.forClass(clazz!) : nil
            
            
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
        
        public func convert(context : ApplicationContext) throws -> ApplicationContext.PropertyDeclaration {
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
    
    class Dependency : Equatable {
        // instance data
        
        var declaration : ApplicationContext.BeanDeclaration
        var successors : [Dependency] = []
        var index : Int? = nil
        var lowLink : Int = 0
        
        // init
        
        init(declaration : ApplicationContext.BeanDeclaration) {
            self.declaration = declaration
        }
    }
    
    // instance data
    
    var context: ApplicationContext
    var handlers = [String:NamespaceHandler]()
    var beans : [ApplicationContext.BeanDeclaration] = []
    var dependencyList : [Dependency] = []
    var dependencies = IdentityMap<ApplicationContext.BeanDeclaration, Dependency>()
    var resolver : Resolver? = nil
    
    // init
    
    init(context: ApplicationContext, data : NSData, namespaceHandlers: [NamespaceHandler]?) throws {
        self.context = context
        
        super.init()
        
        if namespaceHandlers != nil {
            for namespaceHandler in namespaceHandlers! {
                try addNamespaceHandler(namespaceHandler)
            }
        }
        
        try! setupParser()
        
        try! setup()
        
        try parse(data)
    }
    
    // public
    
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
            return try context.configurationManager.getValue(String.self, namespace: fqn.namespace, key: fqn.key) as? String
        }
        
        resolver =  resolveConfiguration
        
        if context.parent == nil {
            // add initial bean declarations so that constructed objects can also refer to those instances
            
            try ApplicationContext.BeanDeclaration(instance: context.injector).collect(context, loader: self)
            try ApplicationContext.BeanDeclaration(instance: context.configurationManager).collect(context, loader: self)
            
            context.injector.register(BeanInjection())
            context.injector.register(ConfigurationValueInjection(configurationManager: context.configurationManager))
        }
    }
    
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
                .property("clazz", xml: "class"),
            
            ClassDefinition(clazz: Property.self, element: "property")
                .property("name")
                .property("value")
                .property("ref")
        )
    }
    
    func convert(beans : Beans) throws -> [ApplicationContext.BeanDeclaration] {
        var beanDeclarations : [ApplicationContext.BeanDeclaration] = []
        
        for declaration in beans.declarations {
            if let bean = declaration as? Bean {
                beanDeclarations.append(try bean.convert(self.context))
            }
            else if let namespaceAware = declaration as? NamespaceAware {
                let namespace = namespaceAware.namespace
                
                let handler = handlers[namespace!]
                
                try handler!.process(namespaceAware, beans: &beanDeclarations)
            }
        }
        
        return beanDeclarations
    }
    
    func addNamespaceHandler(handler : NamespaceHandler) throws  {
        handlers[handler.namespace] = handler
        
        try handler.register(self)
    }
    
    // internal
    
    func getDependency(bean : ApplicationContext.BeanDeclaration) -> Dependency {
        var dependency = dependencies[bean]
        if dependency == nil {
            dependency = Dependency(declaration: bean)
            
            dependencyList.append(dependency!)
            dependencies[bean] = dependency!
        }
        
        return dependency!
    }
    
    func dependency(bean : ApplicationContext.BeanDeclaration, before : ApplicationContext.BeanDeclaration) {
        getDependency(bean).successors.append(getDependency(before))
    }
    
    func addDeclaration(declaration : ApplicationContext.BeanDeclaration) throws -> ApplicationContext.BeanDeclaration {
        // fix scope if not available
        
        if declaration.scope == nil {
            declaration.scope = try context.getScope("singleton")
        }
        
        // add
        
        let dependency = Dependency(declaration: declaration)
        
        dependencies[declaration] = dependency
        dependencyList.append(dependency)
        
        beans.append(try context.addDeclaration(declaration))
        
        return declaration
    }
    
    func sortDependencies(dependencies : [Dependency]) -> [[ApplicationContext.BeanDeclaration]] {
        // closure state
        
        var index = 0
        var stack: [Dependency] = []
        var cycles: [[ApplicationContext.BeanDeclaration]] = []
        
        // local func
        
        func traverse(dependency: Dependency) {
            dependency.index = index
            dependency.lowLink = index
            
            index++
            
            stack.append(dependency) // add to the stack
            
            for successor in dependency.successors {
                if successor.index == nil {
                    traverse(successor)
                    
                    dependency.lowLink = min(dependency.lowLink, successor.lowLink)
                }
                else if stack.contains(successor) {
                    // if the component was not closed yet
                    
                    dependency.lowLink = min(dependency.lowLink, successor.index!)
                }
            } // for
            
            if dependency.lowLink == dependency.index! {
                // if we are in the root of the component
                
                var group:[Dependency] = []
                
                var member: Dependency
                repeat {
                    member = stack.removeLast()
                    
                    group.append(member)
                } while member !== dependency
                
                if group.count > 1 {
                    cycles.append(group.map({$0.declaration}))
                }
            }
        }
        
        // get goin'
        
        for dependency in dependencies {
            if dependency.index == nil {
                traverse(dependency)
            }
        }
        
        return cycles
    }
    
    func process(beans : Beans) throws -> ApplicationContext {
        // collect
        
        if (Tracer.ENABLED) {
            Tracer.trace("loader", level: .HIGH, message: "collect bean information")
        }
        
        var beanDeclarations = try convert(beans)
        
        // collect
        
        for bean in beanDeclarations {
            try bean.collect(context, loader: self)
        }
        
        // connect
        
        if (Tracer.ENABLED) {
            Tracer.trace("loader", level: .HIGH, message: "connect beans")
        }
        
        for bean in beanDeclarations {
            try bean.connect(self)
        }
        
        // sort
        
        let cycles = sortDependencies(dependencyList)
        if cycles.count > 0 {
            let builder = StringBuilder()
            
            builder.append("\(cycles.count) cycles:")
            var index = 0
            for cycle in cycles {
                builder.append("\n\(index): ")
                for declaration in cycle {
                    builder.append(declaration).append(" ")
                }
                
                index++
            }
            
            throw ApplicationContextErrors.CylicDependencies(message: builder.toString())
        }
        
        // sort according to index
        
        dependencyList.sortInPlace({$0.index < $1.index})
        //beanDeclarations.sortInPlace({$0.index < $1.index})
        
        if (Tracer.ENABLED) {
            Tracer.trace("loader", level: .HIGH, message: "resolve beans")
        }
        
        // instantiate all non lazy singletons, etc...
        
        for dependency in dependencyList {
            try dependency.declaration.resolve(self)
        }
        
        // done
        
        return context
    }
    
    // override
    
    override func parse(data : NSData) throws -> AnyObject? {
        let beans = try super.parse(data) as! Beans
        
        // convert
        
        return try process(beans)
    }
}

func ==(lhs: ApplicationContextLoader.Dependency, rhs: ApplicationContextLoader.Dependency) -> Bool {
    return lhs === rhs
}
