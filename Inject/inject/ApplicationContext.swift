//
//  ApplicationContext.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class ApplicationContext : BeanFactory {
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
    
    public class BeanDeclaration : Declaration, Ancestor {
        // instance data
        
        var scope : BeanScope? = nil
        var lazy = false
        var abstract = false
        var parent: BeanDeclaration? = nil
        var singleton : AnyObject?
        var id : String?
        var dependsOn : BeanDeclaration?
        var clazz : BeanDescriptor?
        var properties = [PropertyDeclaration]()
        
        // init
        
        init(id : String) {
            self.id = id
        }
        
        init(instance : AnyObject) {
            self.singleton = instance
            self.clazz = BeanDescriptor.forClass(instance.dynamicType)
        }
        
        override init() {
            super.init()
        }
        
        // fluent stuff
        
        func property(property: PropertyDeclaration) -> BeanDeclaration {
            properties.append(property)
            
            return self
        }
        
        // func
        
        func inheritFrom(parent : BeanDeclaration, loader: ApplicationContextLoader) throws -> Void  {
            var resolveProperties = false
            if clazz == nil {
                clazz = parent.clazz
                
                resolveProperties = true
                
                
                if !abstract {
                    try loader.context.rememberType(self)
                }
            }
            
            if scope == nil {
                scope = parent.scope
            }
            
            // properties
            
            for property in parent.properties {
                // only copy those properties that are not explicitly set here!
                if properties.indexOf({$0.name == property.name}) == nil {
                    properties.append(property)
                }
            }
            
            if resolveProperties {
                for property in properties {
                    try property.resolveProperty(self, loader: loader)
                }
                
            }
        }
        
        
        func collect(context : ApplicationContext, loader: ApplicationContextLoader) throws -> Void {
            try loader.addDeclaration(self)
            
            for property in properties {
                try property.collect(self, context: context, loader: loader)
            }
        }
        
        func connect(loader : ApplicationContextLoader) throws -> Void {
            if dependsOn != nil {
                dependsOn = try loader.context.getDeclarationById(dependsOn!.id!)
                
                loader.dependency(dependsOn!, before: self)
            }
            
            if parent != nil {
                parent = try loader.context.getDeclarationById(parent!.id!)
                
                try inheritFrom(parent!, loader: loader) // copy properties, etc.
                
                loader.dependency(parent!, before: self)
            }
            
            for property in properties {
                try property.connect(self, loader: loader)
            }
            
            // injections
            
            for beanProperty in clazz!.getAllProperties() {
                if beanProperty.autowired {
                    let declaration = try loader.context.getCandidate(beanProperty.getPropertyType())
                    
                    loader.dependency(declaration, before: self)
                }
            }
        }
        
        func resolve(loader : ApplicationContextLoader) throws -> Void {
            // instantiate singletons, etc.
            
            try scope!.prepare(self, factory: loader.context)
        }
        
        func getInstance(context : ApplicationContext) throws -> AnyObject {
            return try scope!.get(self, factory: context)
        }
        
        func create(context : ApplicationContext) throws -> AnyObject {
            if (Tracer.ENABLED) {
                Tracer.trace("loader", level: .HIGH, message: "create \(clazz!.clazz) instance")
            }
            
            let result =  clazz!.create()
            
            // set properties
            
            for property in properties {
                let beanProperty = property.property!
                
                let resolved = try property.resolve(context)
                
                // for some reason string will be converted in a NSContiguousString, or whatever...
                
                if resolved != nil {
                    let type = Types.normalizedType(resolved!)
                    
                    
                    if beanProperty.getPropertyType() != type {
                       try beanProperty.set(result, value: resolved!) // TODO!
                        
                        //throw ApplicationContextErrors.TypeMismatch(message: " property \(Classes.className(clazz!.clazz)).\(beanProperty.getName()) expected a \(beanProperty.getPropertyType()) got \(type)")
                    }
                    else {
                        if (Tracer.ENABLED) {
                            Tracer.trace("loader", level: .HIGH, message: "set \(resolved) as property \(clazz).\(beanProperty.getName())")
                        }
                        
                        try beanProperty.set(result, value: resolved!)
                    }
                }
            }
            
            try context.populateInstance(result);
            
            return result
        }
        
        // Ancestor
        
        func addChild(child : AnyObject) -> Void {
            if child is PropertyDeclaration {
                properties.append(child as! PropertyDeclaration)
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
    
    public class PropertyDeclaration : Declaration, Ancestor {
        // instance data
        
        var name  : String = ""
        var value : AnyObject?
        var ref   : BeanDeclaration?
        var declaration : BeanDeclaration?
        var property : BeanDescriptor.PropertyDescriptor?
        
        // functions
        
        func resolveProperty(beanDeclaration : BeanDeclaration, loader: ApplicationContextLoader) throws -> Void  {
            property = beanDeclaration.clazz!.findProperty(name)
            
            if property == nil {
                throw ApplicationContextErrors.UnknownProperty(property: name, bean: beanDeclaration)
            }
            
            // resolve static values
            
            if let stringValue = value as? String {
                // convert?
                
                if property!.getPropertyType() != String.self {
                    if let conversion = StandardConversionFactory.instance.findConversion(String.self, targetType: property!.getPropertyType()) {
                        do {
                            value = try conversion(object: try loader.resolve(stringValue))
                        }
                        catch ConversionErrors.ConversionException(let value, let targetType, let context) {
                            throw ConversionErrors.ConversionException(value: stringValue, targetType: targetType, context: "[\(origin!.line):\(origin!.column)]")
                        }
                    }
                    else {
                        throw ApplicationContextErrors.TypeMismatch(message: "no conversion applicable between String and \(property!.getPropertyType())")
                    }
                }
                else {
                    value = try loader.resolve(stringValue)
                }
            } // if
        }
        
        func collect(beanDeclaration : BeanDeclaration, context : ApplicationContext, loader: ApplicationContextLoader) throws -> Void {
            if beanDeclaration.clazz != nil { // abstract classes
                try resolveProperty(beanDeclaration, loader: loader)
            }
            
            // done
            
            if declaration != nil {
                try loader.addDeclaration(declaration!)
            }
        }
        
        func connect(beanDeclaration : BeanDeclaration, loader : ApplicationContextLoader) throws -> Void {
            if declaration != nil {
                loader.dependency(declaration!, before: beanDeclaration)
            }
            else if ref != nil {
                ref = try loader.context.getDeclarationById(ref!.id!) // replace with real declaration
                
                loader.dependency(ref!, before: beanDeclaration)
            }
        }
        
        func resolve(context : ApplicationContext) throws -> AnyObject? {
            if ref != nil {
                return ref
            }
            else if declaration != nil {
                return try declaration!.getInstance(context)
            }
            else {
                return value
            }
        }
        
        // Node
        
        func addChild(child : AnyObject) -> Void {
            if let bean = child as? BeanDeclaration {
                declaration = bean
            }
        }
    }
    
    // instance data
    
    var parent : ApplicationContext? = nil
    var injector : Injector
    var configurationManager : ConfigurationManager
    var byType = IdentityMap<AnyObject,ArrayOf<BeanDeclaration>>()
    var byId = [String : BeanDeclaration]()
    var postProcessors = [BeanPostProcessor]()
    var scopes = [String:BeanScope]()
    
    // init
    
    init(parent : ApplicationContext?, data : NSData, namespaceHandlers: [NamespaceHandler]? = nil ) throws {
        if parent != nil {
            self.parent = parent
            
            // inherit stuff
            
            self.injector = parent!.injector
            self.configurationManager = parent!.configurationManager
            // is that good to copy arrays?
            self.postProcessors = parent!.postProcessors
            self.byType = parent!.byType
            self.byId = parent!.byId
            self.scopes = parent!.scopes
            
        }
        else {
            injector = Injector()
            configurationManager = try ConfigurationManager(scope: Scope.WILDCARD)
            
            // default scopes
            
            registerScope(PrototypeScope())
            registerScope(SingletonScope())
        }
        
        try ApplicationContextLoader(context: self, data: data, namespaceHandlers: namespaceHandlers)
    }
    
    // internal
    
    func registerScope(scope : BeanScope) -> Void {
        scopes[scope.name] = scope
    }
    
    func getScope(name : String) throws -> BeanScope{
        let scope = scopes[name]
        if scope == nil {
            throw ApplicationContextErrors.UnknownScope(scope: name, context: "")
        }
        else {
            return scope!
        }
    }
    
    func setParent(parent : ApplicationContext) {
        self.parent = parent
        
        // inherit stuff
        
        self.injector = parent.injector
        self.configurationManager = parent.configurationManager
        // is that good to copy arrays?
        self.postProcessors = parent.postProcessors
        self.byType = parent.byType
        self.byId = parent.byId
    }
    
    func rememberId(declaration : ApplicationContext.BeanDeclaration) throws -> Void {
        if let id = declaration.id {
            if byId[id] == nil {
                byId[id] = declaration
            }
            else {
                throw ApplicationContextErrors.AmbiguousBeanById(id: id, context: "")
            }
        }
    }
    
    func rememberType(declaration : ApplicationContext.BeanDeclaration) throws -> Void {
        // remember by type for injections
        
        var clazz : AnyClass?;
        if declaration.singleton != nil {
            clazz = declaration.singleton!.dynamicType
        }
        else {
            clazz = declaration.clazz?.clazz // may be nil in case of a inherited bean!
        }
        
        if clazz != nil && !declaration.abstract {
            let declarations = byType[clazz!];
            if declarations != nil {
                declarations!.append(declaration)
            }
            else {
                byType[clazz!] = ArrayOf<ApplicationContext.BeanDeclaration>(values: declaration);
            }
        }
    }
    
    func addDeclaration(declaration : ApplicationContext.BeanDeclaration) throws -> ApplicationContext.BeanDeclaration {
        // remember id
        
        if let id = declaration.id { // doesn't matter if abstract or not
            try rememberId(declaration)
        }
        
        // remember by type for injections
        
        if !declaration.abstract {
            try rememberType(declaration)
        }
        
        // done
        
        return declaration
    }
    
    func getCandidate(type : Any.Type) throws -> ApplicationContext.BeanDeclaration {
        let clazz = Classes.unwrapOptional(type)
        
        let candidates = findByType(BeanDescriptor.forClass(clazz))
        
        if candidates.count == 0 {
            throw ApplicationContextErrors.NoCandidateForType(type: clazz)
        }
        if candidates.count > 1 {
            throw ApplicationContextErrors.AmbiguousCandidatesForType(type: clazz)
        }
        else {
            return candidates[0]
        }
    }
    
    func populateInstance(instance : AnyObject) throws -> Void {
        // inject
        
        if (Tracer.ENABLED) {
            Tracer.trace("loader", level: .HIGH, message: "populate a \"\(instance.dynamicType)\"")
        }
        
        try injector.inject(instance, context: self)
        
        // execute processors
        
        for processor in postProcessors {
            processor.process(instance)
        }
        
        // check protocols
        
        // Bean
        
        if let bean = instance as? Bean {
            try bean.postConstruct()
        }
        
        // ContextAware
        
        if var contextAware = instance as? ContextAware {
            contextAware.context = self
        }
        
        // remember post processors
        
        if let postProcessor = instance as? BeanPostProcessor {
            postProcessors.append(postProcessor)
        }
    }
    
    func getDeclarationById(id : String) throws -> ApplicationContext.BeanDeclaration {
        let declaration = byId[id]
        
        if declaration == nil {
            throw ApplicationContextErrors.UnknownBeanById(id: id, context: "")
        }
        
        return declaration!
    }
    
    func findByType(bean : BeanDescriptor) -> [ApplicationContext.BeanDeclaration] {
        // local func
        
        func collect(bean : BeanDescriptor, inout candidates : [ApplicationContext.BeanDeclaration]) -> Void {
            let localCandidates = byType[bean.clazz]
            
            if localCandidates != nil {
                for candidate in localCandidates! {
                    if !candidate.abstract {
                        candidates.append(candidate)
                    }
                }
            }
            
            // check subclasses
            
            for subBean in bean.directSubBeans {
                collect(subBean, candidates: &candidates)
            }
        }
        
        var result : [ApplicationContext.BeanDeclaration] = []
        
        collect(bean, candidates: &result)
        
        return result
    }
    
    // public
    
    //  public func parser(parser: NSXMLParser, didStartElement elementName:
    
    public func getBean(byType type : AnyClass) throws -> AnyObject {
        let result = findByType(BeanDescriptor.forClass(type))
        
        if result.count == 0 {
            throw ApplicationContextErrors.UnknownBeanByType(type: type)
        }
        else if result.count > 1 {
            throw ApplicationContextErrors.AmbiguousBeanByType(type: type)
        }
        else {
            return try result[0].getInstance(self)
        }
    }
    
    public func getBean(byId id : String) throws -> AnyObject {
        if let bean = byId[id] {
            return try bean.getInstance(self)
        }
        else {
            throw ApplicationContextErrors.UnknownBeanById(id: id, context: "")
        }
    }
    
    public func inject(object : AnyObject) throws -> Void {
        try injector.inject(object, context: self)
    }
    
    // BeanFactory
    
    func create(bean : ApplicationContext.BeanDeclaration) throws -> AnyObject {
        return try bean.create(self)
    }
}