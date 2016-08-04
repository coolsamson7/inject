//
//  ApplicationContext.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public typealias Resolver = (key : String) throws -> String?


public class ApplicationContext : BeanFactory {
    // local classes

    class DefaultConstructorFactory : BeanFactory {
        // static data

        static var instance = DefaultConstructorFactory()

        // BeanFactory

        func create(declaration: BeanDeclaration) throws -> AnyObject {
            return declaration.bean!.create()
        }
    }

    class ValueFactory : BeanFactory {
        // instance data

        var object : AnyObject

        // init

        init(object : AnyObject) {
            self.object = object
        }

        // BeanFactory

        func create(bean : BeanDeclaration) throws -> AnyObject {
            return object
        }
    }
    
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
    
    public class BeanDeclaration : Declaration {
        // instance data
        
        var scope : BeanScope? = nil
        var lazy = false
        var abstract = false
        var parent: BeanDeclaration? = nil

        var id : String?
        var dependsOn : BeanDeclaration?
        var bean: BeanDescriptor?
        var target: BeanDescriptor?
        var properties = [PropertyDeclaration]()

        var factory : BeanFactory = DefaultConstructorFactory.instance
        var singleton : AnyObject? = nil
        
        // init
        
        init(id : String) {
            self.id = id
        }
        
        init(instance : AnyObject) {
            self.factory = ValueFactory(object: instance)
            self.singleton = instance
            self.bean = BeanDescriptor.forClass(instance.dynamicType)
        }
        
        override init() {
            super.init()
        }
        
        // fluent stuff

        public func clazz(clazz : String) throws -> BeanDeclaration {
            self.bean = try BeanDescriptor.forClass(clazz)

            return self
        }


        public func id(id : String) -> BeanDeclaration {
            self.id = id

            return self
        }

        public func lazy(lazy : Bool = true) -> BeanDeclaration {
            self.lazy = lazy

            return self
        }

        public func abstract(abstract : Bool = true) -> BeanDeclaration {
            self.abstract = abstract

            return self
        }

        public func scope(scope : BeanScope) -> BeanDeclaration {
            self.scope = scope

            return self
        }

        public func dependsOn(depends : String) -> BeanDeclaration {
            self.dependsOn = BeanDeclaration(id: depends)

            return self
        }

        public func parent(parent : BeanDeclaration) -> BeanDeclaration {
            self.parent = parent // TODO string / Bean?

            return self
        }

        public func property(name: String, value : Any? = nil, ref : String? = nil, resolve : String? = nil, bean : BeanDeclaration? = nil, inject : InjectBean? = nil) -> BeanDeclaration {
            let property = PropertyDeclaration()

            property.name = name

            // TODO: sanity check
            if ref != nil {
                property.value = ApplicationContext.BeanReference(ref: ref!)
            }
            else if resolve != nil {
                property.value = ApplicationContext.PlaceHolder(value: resolve!)
            }
            else if bean != nil {
                property.value = ApplicationContext.EmbeddedBean(bean: bean!)
            }
            else if inject != nil {
                property.value = ApplicationContext.InjectedBean(inject: inject!)
            }
            else {
                property.value = ApplicationContext.Value(value: value!)
            }

            properties.append(property)
            
            return self
        }

        public func target(target : String) throws -> BeanDeclaration {
            self.target = try BeanDescriptor.forClass(target)

            return self
        }

        public func property(property: PropertyDeclaration) -> BeanDeclaration {
            properties.append(property)

            return self
        }
        
        // func

        func report(builder : StringBuilder) {
            builder.append(Classes.className(bean!.clazz))
            if id != nil {
                builder.append("[\"\(id!)\"]")
            }

            if lazy {
                builder.append(" lazy: true")
            }

            if abstract {
                builder.append(" abstract: true")
            }

            if self.scope!.name != "singleton" {
                builder.append(" scope: \(scope!.name)")
            }

            builder.append("\n")
        }
        
        func inheritFrom(parent : BeanDeclaration, loader: ApplicationContext.Loader) throws -> Void  {
            var resolveProperties = false
            if bean == nil {
                bean = parent.bean
                
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
        
        func collect(context : ApplicationContext, loader: ApplicationContext.Loader) throws -> Void {
            for property in properties {
                try property.collect(self, context: context, loader: loader)
            }
        }
        
        func connect(loader : ApplicationContext.Loader) throws -> Void {
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
            
            for beanProperty in bean!.getAllProperties() {
                if beanProperty.autowired {
                    let declaration = try loader.context.getCandidate(beanProperty.getPropertyType() as! AnyClass)
                    
                    loader.dependency(declaration, before: self)
                }
            }
        }
        
        func resolve(loader : ApplicationContext.Loader) throws -> Void {
            for property in properties {
                try property.resolve(loader)

                if !checkTypes(property.getType(), expected: property.property!.getPropertyType()) {
                    throw ApplicationContextErrors.TypeMismatch(message: " property \(Classes.className(bean!.clazz)).\(property.name) expected a \(property.property!.getPropertyType()) got \(property.getType())")
                }
            }
        }

        func prepare(loader : ApplicationContext.Loader) throws -> Void {
            try scope!.prepare(self, factory: loader.context)

            // check for post processors

            if bean!.clazz is BeanPostProcessor.Type {
                if (Tracer.ENABLED) {
                    Tracer.trace("inject.runtime", level: .HIGH, message: "add post processor \(bean!.clazz)")
                }

                loader.context.postProcessors.append(try self.getInstance(loader.context) as! BeanPostProcessor) // sanity checks
            }
        }

        func checkTypes(type: Any.Type, expected : Any.Type) -> Bool {
            if type != expected {
                if let expectedClazz = expected as? AnyClass {
                    if let clazz = type as? AnyClass {
                        if !clazz.isSubclassOfClass(expectedClazz) {
                            return false
                        }
                    }
                    else {
                        return false
                    }
                }
                else {
                    return false
                }
            }

            return true
        }
        
        func getInstance(context : ApplicationContext) throws -> AnyObject {
            return try scope!.get(self, factory: context)
        }
        
        func create(context : ApplicationContext) throws -> AnyObject {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .HIGH, message: "create instance of \(bean!.clazz)")
            }
            
            let result = try factory.create(self) // constructor, value, etc
            
            // set properties
            
            for property in properties {
                let beanProperty = property.property!
                let resolved = try property.get(context)

                if resolved != nil {
                    if (Tracer.ENABLED) {
                        Tracer.trace("inject.runtime", level: .FULL, message: "set \(Classes.className(bean!.clazz)).\(beanProperty.getName()) = \(resolved!)")
                    }

                    try beanProperty.set(result, value: resolved)
                } // if
            }

            // run processors
            
            return try context.runPostProcessors(result);
        }
        
        // CustomStringConvertible
        
        override public var description: String {
            let builder = StringBuilder();
            
            builder.append("bean(class: \(bean)")
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

    // these classes act as containers for various ways to reference values

    class ValueHolder {
        func collect(loader : ApplicationContext.Loader, beanDeclaration : BeanDeclaration) throws -> Void {
            // noop
        }

        func connect(loader : ApplicationContext.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            // noop
        }

        func resolve(loader : ApplicationContext.Loader, type : Any.Type) throws -> ValueHolder {
            return  self
        }

        func get(context : ApplicationContext) throws -> Any {
            fatalError("ValueHolder.get is abstract")
        }

        func getType() -> Any.Type {
            fatalError("ValueHolder.getType is abstract")
        }
    }

    class BeanReference : ValueHolder {
        // instance data

        var ref : BeanDeclaration

        // init

        init(ref : String) {
            self.ref = BeanDeclaration(id: ref)
        }

        // override

        override func connect(loader : ApplicationContext.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            ref = try loader.context.getDeclarationById(ref.id!) // replace with real declaration

            loader.dependency(ref, before: beanDeclaration)
        }


        override func get(context : ApplicationContext) throws -> Any {
            return try ref.getInstance(context)
        }

        override func getType() -> Any.Type {
            return ref.bean!.clazz
        }
    }

    class InjectedBean : ValueHolder {
        // instance data

        var inject : InjectBean
        var bean : BeanDeclaration?

        // init

        init(inject : InjectBean) {
            self.inject = inject
        }

        // override

        override func connect(loader : ApplicationContext.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            if inject.id != nil {
                bean = try loader.context.getDeclarationById(inject.id!)
            }
            else {
                bean = try loader.context.getCandidate(type as! AnyClass)
            }

            loader.dependency(bean!, before: beanDeclaration)
        }

        override func get(context : ApplicationContext) throws -> Any {
            return try bean!.getInstance(context)
        }

        override func getType() -> Any.Type {
            return bean!.bean!.clazz
        }
    }

    class EmbeddedBean : ValueHolder {
        // instance data

        var bean : BeanDeclaration

        // init

        init(bean : BeanDeclaration) {
            self.bean = bean
        }

        // override

        override func collect(loader : ApplicationContext.Loader, beanDeclaration : BeanDeclaration) throws -> Void {
            try loader.context.define(bean)
        }

        override func connect(loader : ApplicationContext.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            loader.dependency(bean, before: beanDeclaration)
        }

        override func get(context : ApplicationContext) throws -> Any {
            return try bean.getInstance(context)
        }

        override func getType() -> Any.Type {
            return bean.bean!.clazz
        }
    }

    class Value : ValueHolder {
        // instance data

        var value : Any

        // init

        init(value : Any) {
            self.value = value
        }

        // override

        override func get(context : ApplicationContext) throws -> Any {
            return value
        }

        override func getType() -> Any.Type {
            return value.dynamicType
        }
    }

    class PlaceHolder : ValueHolder {
        // instance data

        var value : String

        // init

        init(value : String) {
            self.value = value
        }

        // override

        override func resolve(loader : ApplicationContext.Loader, type : Any.Type) throws -> ValueHolder {
            // replace placeholders first...

            value = try loader.resolve(value)

            var result : Any = value;

            // check for conversions

            if type != String.self {
                if let conversion = StandardConversionFactory.instance.findConversion(String.self, targetType: type) {
                    do {
                        result = try conversion(object: value)
                    }
                            catch ConversionErrors.ConversionException( _, let targetType, _) {
                        throw ConversionErrors.ConversionException(value: value, targetType: targetType, context: "")//[\(origin!.line):\(origin!.column)]")
                    }
                }
                else {
                    throw ApplicationContextErrors.TypeMismatch(message: "no conversion applicable between String and \(type)")
                }
            }
            // done

            return Value(value: result)
        }
    }
    
    public class PropertyDeclaration : Declaration {
        // instance data
        
        var name  : String = ""
        var value : ValueHolder?
        var property : BeanDescriptor.PropertyDescriptor?
        
        // functions
        
        func resolveProperty(beanDeclaration : BeanDeclaration, loader: ApplicationContext.Loader) throws -> Void  {
            property = beanDeclaration.bean!.findProperty(name)
            
            if property == nil {
                throw ApplicationContextErrors.UnknownProperty(property: name, bean: beanDeclaration)
            }
        }
        
        func collect(beanDeclaration : BeanDeclaration, context : ApplicationContext, loader: ApplicationContext.Loader) throws -> Void {
            if beanDeclaration.bean != nil { // abstract classes
                try resolveProperty(beanDeclaration, loader: loader)
            }
            else {
                print("ocuh")
            }

            try value!.collect(loader, beanDeclaration: beanDeclaration)
        }
        
        func connect(beanDeclaration : BeanDeclaration, loader : ApplicationContext.Loader) throws -> Void {
            if property == nil {
                // HACK...dunno why...
                try resolveProperty(beanDeclaration, loader: loader)
            }

            try value!.connect(loader, beanDeclaration: beanDeclaration, type: property!.getPropertyType())
        }
        
        func resolve(loader : ApplicationContext.Loader) throws -> Any? {
            return try value = value!.resolve(loader, type: property!.getPropertyType())
        }

        func get(context : ApplicationContext) throws -> Any? {
            return try value!.get(context)
        }

        func getType() -> Any.Type {
            return value!.getType()
        }
    }

    // default scopes

    public class PrototypeScope : BeanScope {
        // Scope

        public var name : String {
            get {
                return "prototype"
            }
        }

        public func prepare(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws {
            // noop
        }

        public func get(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
            return try factory.create(bean)
        }

        public func finish() {
            // noop
        }
    }

    public class SingletonScope : BeanScope {
        // Scope

        public var name : String {
            get {
                return "singleton"
            }
        }

        public func prepare(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws {
            if !bean.lazy {
                try get(bean, factory: factory)
            }
        }

        public func get(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
            if bean.singleton == nil {
                bean.singleton = try factory.create(bean)
            }

            return bean.singleton!
        }

        public func finish() {
            // noop
        }
    }

    class BeanFactoryScope : BeanScope {
        // instance data

        let declaration : ApplicationContext.BeanDeclaration
        let context: ApplicationContext

        // init

        init(declaration : ApplicationContext.BeanDeclaration, context: ApplicationContext) {
            self.declaration = declaration
            self.context = context
        }

        // BeanScope

        var name : String {
            get {
                return "does not matter"
            }
        }

        func prepare(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws {
            // noop
        }

        func get(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
            if let factoryBean = try declaration.getInstance(context) as? FactoryBean {
                return try factoryBean.create()
            }

            fatalError("cannot happen")
        }

        func finish() {
            // noop
        }
    }

    public class Loader {
        // local classes

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
        var loading = false
        var dependencyList : [Dependency] = []
        var dependencies = IdentityMap<ApplicationContext.BeanDeclaration, Dependency>()
        var resolver : Resolver? = nil

        // init

        init(context: ApplicationContext) {
            self.context = context
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
                        Tracer.trace("inject.configuration", level: .HIGH, message: "resolve configuration key \(key) = \(resolved)")
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
                        Tracer.trace("inject.configuration", level: .HIGH, message: "resolve configuration key \(key) = \(resolved)")
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
            // add

            let dependency = Dependency(declaration: declaration)

            dependencies[declaration] = dependency
            dependencyList.append(dependency)

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

                index += 1

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
                    // root of a component

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

        func load() throws -> ApplicationContext {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "load \(context.name)")
            }

            loading = true

            try setup()

            // collect

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "collect beans")
            }

            for dependency in dependencyList {
                try dependency.declaration.collect(context, loader: self) // define
            }

            // connect

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "connect beans")
            }

            for dependency in dependencyList {
                try dependency.declaration.connect(self)
            }

            // sort

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "sort beans")
            }

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

                    index += 1
                }

                throw ApplicationContextErrors.CylicDependencies(message: builder.toString())
            }

            // sort according to index

            dependencyList.sortInPlace({$0.index < $1.index})

            // and resort local beans

            context.localBeans.sortInPlace({dependencies[$0]!.index < dependencies[$1]!.index})

            // resolve

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "resolve beans")
            }

            for dependency in dependencyList {
                let bean = dependency.declaration

                try bean.resolve(self)
            }


            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "prepare beans")
            }

            for dependency in dependencyList {
                try dependency.declaration.prepare(self)  // instantiate all non lazy singletons, add post processors, etc...
            }

            // done

            return context
        }
    }

    class ApplicationContextPostProcessor: NSObject, ContextAware, BeanPostProcessor {
        // instance data

        var injector : Injector
        var _context : ApplicationContext?
        var context : ApplicationContext? {
            get {
                return _context
            }
            set {
                _context = newValue
            }
        }

        // init

        // needed by the BeanDescriptor
        override init() {
            self.injector = Injector()
            super.init()
        }

        init(context : ApplicationContext) {
            self.injector = context.injector
            self._context = context


            super.init()
        }

        // BeanPostProcessor

        func process(instance : AnyObject) throws -> AnyObject {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .HIGH, message: "default post process a \"\(instance.dynamicType)\"")
            }

            // inject

            try injector.inject(instance, context: context!)

            // check protocols

            // Bean

            if let bean = instance as? Bean {
                try bean.postConstruct()
            }

            // ContextAware

            if var contextAware = instance as? ContextAware {
                contextAware.context = context!
            }

            // done

            return instance
        }
    }

    // instance data

    var name : String = ""
    var loader : Loader?
    var parent : ApplicationContext? = nil
    var injector : Injector
    var configurationManager : ConfigurationManager
    var byType = IdentityMap<AnyObject,ArrayOf<BeanDeclaration>>()
    var byId = [String : BeanDeclaration]()
    var postProcessors = [BeanPostProcessor]()
    var scopes = [String:BeanScope]()
    var localBeans = [BeanDeclaration]()

    var singletonScope : BeanScope
    
    // init
    
    init(name: String, parent : ApplicationContext? = nil) throws {
        self.name = name

        if parent != nil {
            self.parent = parent
            self.injector = parent!.injector
            self.configurationManager = parent!.configurationManager
            self.singletonScope = parent!.singletonScope
            self.scopes = parent!.scopes

            self.byType = parent!.byType
            self.byId = parent!.byId

            loader = Loader(context: self)
        }
        else {
            // configuration manager

            configurationManager = try ConfigurationManager(scope: Scope.WILDCARD)

            // injector

            injector = Injector()

            injector.register(BeanInjection())
            injector.register(ConfigurationValueInjection(configurationManager: configurationManager))

            // default scopes

            singletonScope = SingletonScope() // cache scope

            registerScope(PrototypeScope())
            registerScope(singletonScope)

            // set loader here in order to prevent exception..

            loader = Loader(context: self)

            // add initial bean declarations so that constructed objects can also refer to those instances

            try define(BeanDeclaration(instance: injector))
            try define(BeanDeclaration(instance: configurationManager))

            // default post processor

            //postProcessors.append(ApplicationContextProcessor(context: self))

            try define(BeanDeclaration(instance: ApplicationContextPostProcessor(context: self))) // should be the first bean!
        }
    }

    // public

    public func loadXML(data : NSData) throws {
        try XMLContextLoader(context: self, data: data)
    }

    public func refresh() throws {
        if loader != nil {
            // check parent

            if parent != nil {
                try parent!.validate()

                inheritFrom(parent!)
            }

            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .HIGH, message: "refresh \(name)")
            }

            // load

            try loader!.load()

            // report

            //report()

            loader = nil // prevent double loading...
        }
    }

    public func registerScope(scope : BeanScope) -> Void {
        scopes[scope.name] = scope
    }

    // fluent

    public func scope(scope : String) throws -> BeanScope {
        return try getScope(scope)
    }

    public func bean(instance : AnyObject, id : String? = nil, scope :  String = "singleton") throws -> ApplicationContext.BeanDeclaration {
        let result = ApplicationContext.BeanDeclaration(instance: instance)

        if id != nil {
            result.id = id
        }

        //result.scope = try self.scope(scope)

        return result
    }

    public func bean(className : String, id : String? = nil) throws -> ApplicationContext.BeanDeclaration {
        let result = ApplicationContext.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        result.bean = try BeanDescriptor.forClass(className)

        return result
    }

    public func bean(clazz : AnyClass, id : String? = nil) throws -> ApplicationContext.BeanDeclaration {
        let result = ApplicationContext.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        result.bean = BeanDescriptor.forClass(clazz)

        return result
    }

    public func define(declaration : ApplicationContext.BeanDeclaration) throws -> ApplicationContext {
        // fix scope if not available

        if declaration.scope == nil {
            declaration.scope = singletonScope
        }

        // pass to loader if set

        if loader != nil {
            try loader!.addDeclaration(declaration)
        }
        else {
            throw ApplicationContextErrors.Exception(message: "context is frozen")
        }

        // remember id

        if declaration.id != nil { // doesn't matter if abstract or not
            try rememberId(declaration)
        }

        // remember by type for injections

        if !declaration.abstract {
            try rememberType(declaration)
        }

        // local beans

        localBeans.append(declaration)

        // done

        return self
    }

    // internal

    func inheritFrom(parent : ApplicationContext) {
        if (Tracer.ENABLED) {
            Tracer.trace("inject.loader", level: .HIGH, message: "inherit from \(parent.name)")
        }

        self.postProcessors = parent.postProcessors

        // nor merge for dictionaries...

        //self.byType = parent.byType
        //self.byId = parent.byId

        // patch ContextAware

        for declaration in parent.localBeans {
            if var contextAware = declaration.singleton as? ContextAware { // does not make sense for beans other than singletons...
                contextAware.context = self
            }
        }
    }


    func report() {
        let builder = StringBuilder()

        builder.append("### \(name) beans:\n")

        for bean in localBeans {
            bean.report(builder)
        }

        builder.append("\n")

        print(builder.toString())
    }

    func validate() throws {
        if loader != nil && !loader!.loading {
            try refresh()
        }
    }

    func getScope(name : String) throws -> BeanScope {
        let scope = scopes[name]
        if scope == nil {
            throw ApplicationContextErrors.UnknownScope(scope: name, context: "")
        }
        else {
            return scope!
        }
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
        if let valueFactory = declaration.factory as? ValueFactory {
            clazz = valueFactory.object.dynamicType
        }
        else {
            clazz = declaration.bean?.clazz // may be nil in case of a inherited bean!
        }

        // is that a factory bean?

        if clazz is FactoryBean.Type {
            let target = declaration.target
            if target == nil {
                fatalError("missing target");
            }

            // include artificial bean declaration with special scope

            let bean = BeanDeclaration()

            bean.scope = BeanFactoryScope(declaration : declaration, context: self)
            bean.dependsOn = declaration
            bean.bean = target

            // remember

            try rememberType(bean)
        } // if
        
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

    func getCandidate(clazz : AnyClass) throws -> ApplicationContext.BeanDeclaration {
        let candidates = getBeansByType(BeanDescriptor.forClass(clazz))
        
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
    
    func runPostProcessors(instance : AnyObject) throws -> AnyObject {
        var result = instance

        // inject
        
        if (Tracer.ENABLED) {
            Tracer.trace("inject.runtime", level: .HIGH, message: "run post processors on a \"\(result.dynamicType)\"")
        }

        for processor in postProcessors {
            result = try processor.process(result)
        }

        return result
    }
    
    func getDeclarationById(id : String) throws -> ApplicationContext.BeanDeclaration {
        let declaration = byId[id]
        
        if declaration == nil {
            throw ApplicationContextErrors.UnknownBeanById(id: id, context: "")
        }
        
        return declaration!
    }

    // public

    public func getBeansByType(clazz : AnyClass) -> [ApplicationContext.BeanDeclaration] {
        return getBeansByType(BeanDescriptor.forClass(clazz))
    }

    public func getBeansByType(bean : BeanDescriptor) -> [ApplicationContext.BeanDeclaration] {
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

    public func getBean<T>(type : T.Type, byId id : String? = nil) throws -> T {
        try validate()

        if id != nil {
            if let bean = self.byId[id!] {
                return try bean.getInstance(self) as! T
            }
            else {
                throw ApplicationContextErrors.UnknownBeanById(id: id!, context: "")
            }
        }
        else {
            let result = getBeansByType(BeanDescriptor.forClass(type as! AnyClass))
            
            if result.count == 0 {
                throw ApplicationContextErrors.UnknownBeanByType(type: type as! AnyClass)
            }
            else if result.count > 1 {
                throw ApplicationContextErrors.AmbiguousBeanByType(type: type as! AnyClass)
            }
            else {
                return try result[0].getInstance(self) as! T
            }

        }
    }

    // without generics...this sucks
    public func getBean(type : AnyClass, byId id : String? = nil) throws -> AnyObject {
        try validate()

        if id != nil {
            if let bean = self.byId[id!] {
                return try bean.getInstance(self) 
            }
            else {
                throw ApplicationContextErrors.UnknownBeanById(id: id!, context: "")
            }
        }
        else {
            let result = getBeansByType(BeanDescriptor.forClass(type ))

            if result.count == 0 {
                throw ApplicationContextErrors.UnknownBeanByType(type: type )
            }
            else if result.count > 1 {
                throw ApplicationContextErrors.AmbiguousBeanByType(type: type )
            }
            else {
                return try result[0].getInstance(self)
            }

        }
    }
    
    public func inject(object : AnyObject) throws -> Void {
        try validate()

        try injector.inject(object, context: self)
    }
    
    public func getConfigurationManager() -> ConfigurationManager {
        return configurationManager
    }
    
    // BeanFactory
    
    public func create(bean : ApplicationContext.BeanDeclaration) throws -> AnyObject {
        return try bean.create(self)
    }
}

func ==(lhs: ApplicationContext.Loader.Dependency, rhs: ApplicationContext.Loader.Dependency) -> Bool {
    return lhs === rhs
}