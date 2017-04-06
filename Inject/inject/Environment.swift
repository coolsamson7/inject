//
//  Environment.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public typealias Resolver = (_ key : String) throws -> String?

/// this factory creates instances by calling a specified function
class FactoryFactory<T> : BeanFactory {
    // MARK: instance data

    var factory : () throws -> T

    // MARK: init

    internal init(factory : @escaping () throws -> T ) {
        self.factory = factory
    }

    // MARK: implement BeanFactory

    func create(_ bean : Environment.BeanDeclaration) throws -> AnyObject {
        return try factory() as AnyObject
    }
}

/// `Environment`is the central class that collects bean informations and takes care of their lifecycle
open class Environment: BeanFactory {
    // MARK: local classes

    open class UnresolvedScope : AbstractBeanScope {
        // MARK: init

        override init(name : String) {
            super.init(name: name)
        }
    }

    /// this factory calls the default constructor of the given class
    class DefaultConstructorFactory : BeanFactory {
        // static data

        static var instance = DefaultConstructorFactory()

        // MARK: implement BeanFactory

        func create(_ declaration: BeanDeclaration) throws -> AnyObject {
            return try declaration.bean.create()
        }
    }

    /// this factory returns a fixed object
    class ValueFactory : BeanFactory {
        // MARK: instance data

        var object : AnyObject

        // init

        init(object : AnyObject) {
            self.object = object
        }

        // MARK: implement BeanFactory

        func create(_ bean : BeanDeclaration) throws -> AnyObject {
            return object
        }
    }
    
    open class Declaration : NSObject, OriginAware {
        // MARK: instance data
        
        var _origin : Origin?
        
        // MARK: implement OriginAware
        
        open var origin : Origin? {
            get {
                return _origin
            }
            set {
                _origin = newValue
            }
        }
    }

    /// An `BeanDeclaration` collects the necessary information to construct a particular instance.
    /// This covers
    /// * the class
    /// * the scope: "singleton", "prototype" or custom. "singleton" is the default
    /// * lazy attribute. The default is `false`
    /// * optional id of a parent bean if, that defines common attributes that will be inherited
    /// * properties
    /// * the target class for factory beans
    open class BeanDeclaration : Declaration {
        // MARK: local classes

        class Require {
            var clazz : AnyClass?
            var id    : String?
            var bean  : BeanDeclaration?

            init(clazz : AnyClass? = nil, id : String? = nil, bean  : BeanDeclaration? = nil) {
                self.clazz = clazz
                self.id    = id
                self.bean  = bean
            }
        }

        // MARK: instance data
        
        var scope : BeanScope? = nil
        var lazy = false
        var abstract = false
        var parent: BeanDeclaration? = nil

        var id : String?
        var requires : [Require] = []
        var clazz : AnyClass?
        var _bean: BeanDescriptor?

        var bean : BeanDescriptor {
            get {
                if _bean == nil {
                    _bean = try! BeanDescriptor.forClass(clazz!)
                }

                return _bean!
            }
        }

        var implements = [Any.Type]()
        var target: AnyClass?
        var properties = [PropertyDeclaration]()

        var factory : BeanFactory = DefaultConstructorFactory.instance
        var singleton : AnyObject? = nil
        
        // init

        /// create a new `BeanDeclaration`
        /// - Parameter id:  the id
        init(id : String) {
            self.id = id
        }

        /// create a new `BeanDeclaration`
        /// - Parameter instance:  a fixed instance
        init(instance : AnyObject) {
            self.factory = ValueFactory(object: instance)
            //self.singleton = instance // this is not done on purpose since we want the post processors to run!
            self.clazz = type(of: instance)
        }

        /// create a new `BeanDeclaration`
        override init() {
            super.init()
        }
        
        // MARK: fluent stuff

        /// set the class of this bean declaration
        /// - Parameter className: the class name
        /// - Returns: self
        open func clazz(_ className : String) throws -> Self {
            self.clazz = try Classes.class4Name(className)

            return self
        }

        /// set the id of this bean declaration
        /// - Parameter id: the id
        /// - Returns: self
        open func id(_ id : String) -> Self {
            self.id = id

            return self
        }

        /// set the `lazy' attribute of this bean declaration
        /// - Parameter lazy: if `true`, the instance will be created whenever it is requested for the first time
        /// - Returns: self
        open func lazy(_ lazy : Bool = true) -> Self {
            self.lazy = lazy

            return self
        }

        /// set the `abstract' attribute of this bean declaration
        /// - Parameter abstract: if `true`, the instance will not be craeted but serves only as a template for inherited beans
        /// - Returns: self
        open func abstract(_ abstract : Bool = true) -> Self {
            self.abstract = abstract

            return self
        }

        /// set the scope of this bean declaration
        /// - Parameter scope: the scope
        /// - Returns: self
        open func scope(_ scope : BeanScope) -> Self {
            self.scope = scope

            return self
        }

        /// set the scope of this bean declaration
        /// - Parameter scope: the scope
        /// - Returns: self
        open func scope(_ scope : String) -> Self {
            self.scope = UnresolvedScope(name: scope)

            return self
        }

        /// specifies that this bean needs to be constructed after another bean
        /// - Parameter depends: the id of the bean which needs to be constructed first
        /// - Returns: self
        open func dependsOn(_ depends : String) -> Self {
            requires(id: depends)

            return self
        }

        /// specifies that this bean needs to be constructed after another bean
        /// - Parameter id: the id of the bean which needs to be constructed first
        /// - Returns: self
        open func requires(id: String) -> Self {
            requires.append(Require(id: id))

            return self
        }

        /// specifies that this bean needs to be constructed after another bean
        /// - Parameter class: the class of the bean which needs to be constructed first
        /// - Returns: self
        open func requires(class clazz: AnyClass) -> Self {
            requires.append(Require(clazz: clazz))

            return self
        }

        /// specifies that this bean needs to be constructed after another bean
        /// - Parameter bean: the bean which needs to be constructed first
        /// - Returns: self
        open func requires(bean : BeanDeclaration) -> Self {
            requires.append(Require(bean: bean))

            return self
        }

        /// specifies a bean that will serve as a template
        /// - Parameter parent: the id of the parent bean
        /// - Returns: self
        open func parent(_ parent : String) -> Self {
            self.parent = BeanDeclaration(id: parent)

            return self
        }

        /// create a new property given its name and one of possible parameters
        /// - Parameter name: the name of the property
        /// - Parameter value: a fixed value
        /// - Parameter ref: the id of a referenced bean
        /// - Parameter resolve: a placeholder that will be evaluated in the current configuration context and possibly transformed in rhe required type
        /// - Parameter bean: an embedded bean defining the value
        /// - Parameter inject: an `InjectBean` instance that defines how the injection shuld be carried out ( by id or by type )
        /// - Returns: self
        open func property(_ name: String, value : Any? = nil, ref : String? = nil, resolve : String? = nil, bean : BeanDeclaration? = nil, inject : InjectBean? = nil) -> Self {
            let property = PropertyDeclaration()

            property.name = name

            // TODO: sanity check
            if ref != nil {
                property.value = Environment.BeanReference(ref: ref!)
            }
            else if resolve != nil {
                property.value = Environment.PlaceHolder(value: resolve!)
            }
            else if bean != nil {
                property.value = Environment.EmbeddedBean(bean: bean!)
            }
            else if inject != nil {
                property.value = Environment.InjectedBean(inject: inject!)
            }
            else {
                property.value = Environment.Value(value: value!)
            }

            properties.append(property)
            
            return self
        }

        /// specifies a target class of a factory bean
        /// - Parameter clazz: the class that this factory beans creates
        /// - Returns: self
        open func target(_ clazz : AnyClass) throws -> Self {
            self.target = clazz

            return self
        }

        /// add a new property
        /// - Parameter property : a `PropertyDeclaration`
        /// - Returns: self
        open func property(_ property: PropertyDeclaration) -> Self {
            properties.append(property)

            return self
        }

        // specifies that the corresponding instance implements a number of types

        open func implements(_ types : Any.Type...) throws -> Self {
            self.implements = types

            return self
        }

        // MARK: internal

        func report(_ builder : StringBuilder) {
            builder.append(Classes.className(clazz!))
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

            if origin != nil {
                builder.append(" origin: \(origin!)")
            }

            builder.append("\n")
        }
        
        func inheritFrom(_ parent : BeanDeclaration, loader: Environment.Loader) throws -> Void  {
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
                if properties.index(where: {$0.name == property.name}) == nil {
                    properties.append(property)
                }
            }
            
            if resolveProperties {
                for property in properties {
                    try property.resolveProperty(self, loader: loader)
                }
            }
        }
        
        func collect(_ environment: Environment, loader: Environment.Loader) throws -> Void {
            for property in properties {
                try property.collect(self, environment: environment, loader: loader)
            }
        }
        
        func connect(_ loader : Environment.Loader) throws -> Void {
            for require in requires {
                if let bean = require.bean {
                    loader.dependency(bean, before: self)
                }
                else if let id = require.id {
                    loader.dependency(try loader.context.getDeclarationById(id), before: self)
                }
                else if let clazz = require.clazz {
                    loader.dependency(try loader.context.getCandidate(clazz), before: self)
                }
            } // for
            
            if parent != nil {
                parent = try loader.context.getDeclarationById(parent!.id!)
                
                try inheritFrom(parent!, loader: loader) // copy properties, etc.
                
                loader.dependency(parent!, before: self)
            }
            
            for property in properties {
                try property.connect(self, loader: loader)
            }

            if let descriptor = BeanDescriptor.findBeanDescriptor(clazz!) { // do not create the descriptor on demand!
                // injections

                for beanProperty in descriptor.getProperties() {
                    if beanProperty.autowired {
                        let declaration = try loader.context.getCandidate(beanProperty.getPropertyType())

                        loader.dependency(declaration, before: self)
                    } // if
                } // for
            } // if
        }
        
        func resolve(_ loader : Environment.Loader) throws -> Void {
            // resolve scope?

            if let scope = self.scope as? UnresolvedScope {
                self.scope = try loader.context.getScope(scope.name)
            }

            // resolve properties

            for property in properties {
                try property.resolve(loader)

                if !checkTypes(property.getType(), expected: property.property!.getPropertyType()) {
                    throw EnvironmentErrors.typeMismatch(message: " property \(Classes.className(clazz!)).\(property.name) expected a \(property.property!.getPropertyType()) got \(property.getType())")
                }
            }
        }

        func prepare(_ loader : Environment.Loader) throws -> Void {
            try scope!.prepare(self, factory: loader.context)

            // check for post processors

            if clazz is BeanPostProcessor.Type {
                if (Tracer.ENABLED) {
                    Tracer.trace("inject.runtime", level: .high, message: "add post processor \(String(describing: clazz))")
                }

                loader.context.postProcessors.append(try self.getInstance(loader.context) as! BeanPostProcessor) // sanity checks
            }
        }

        func checkTypes(_ type: Any.Type, expected : Any.Type) -> Bool {
            if type != expected {
                if let expectedClazz = expected as? AnyClass {
                    if let clazz = type as? AnyClass {
                        if !clazz.isSubclass(of: expectedClazz) {
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
        
        func getInstance(_ environment: Environment) throws -> AnyObject {
            return try scope!.get(self, factory: environment)
        }
        
        func create(_ environment: Environment) throws -> AnyObject {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .high, message: "create instance of \(clazz!)")
            }
            
            let result = try factory.create(self) // MARK: constructor, value, etc

            // make sure that the bean descriptor is initialized since we need the class hierarchy for subsequent bean requests!

            if _bean == nil {
                if let beanDescriptor = BeanDescriptor.findBeanDescriptor(type(of: result)) {
                    _bean = beanDescriptor
                }
                else {
                    // create manually with instance avoiding the generic init call
                    _bean = try BeanDescriptor(instance: result)
                }

                for prot in implements {
                    try _bean!.implements(prot)
                }
            }

            // set properties
            
            for property in properties {
                let beanProperty = property.property!
                let resolved = try property.get(environment)

                if resolved != nil {
                    if (Tracer.ENABLED) {
                        Tracer.trace("inject.runtime", level: .full, message: "set \(Classes.className(clazz!)).\(beanProperty.getName()) = \(resolved!)")
                    }

                    try beanProperty.set(result, value: resolved)
                } // if
            }

            // run processors
            
            return try environment.runPostProcessors(result)
        }
        
        // CustomStringConvertible
        
        override open var description: String {
            let builder = StringBuilder()
            
            builder.append("bean(class: \(String(describing: clazz))")
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
        func collect(_ loader : Environment.Loader, beanDeclaration : BeanDeclaration) throws -> Void {
            // noop
        }

        func connect(_ loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            // noop
        }

        func resolve(_ loader : Environment.Loader, type : Any.Type) throws -> ValueHolder {
            return  self
        }

        func get(_ environment: Environment) throws -> Any {
            fatalError("\(type(of: self)).get is abstract")
        }

        func getType() -> Any.Type {
            fatalError("\(type(of: self)).getType is abstract")
        }
    }

    class BeanReference : ValueHolder {
        // MARK: instance data

        var ref : BeanDeclaration

        // init

        init(ref : String) {
            self.ref = BeanDeclaration(id: ref)
        }

        // override

        override func connect(_ loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            ref = try loader.context.getDeclarationById(ref.id!) // replace with real declaration

            loader.dependency(ref, before: beanDeclaration)
        }


        override func get(_ environment: Environment) throws -> Any {
            return try ref.getInstance(environment)
        }

        override func getType() -> Any.Type {
            return ref.clazz!
        }
    }

    class InjectedBean : ValueHolder {
        // MARK: instance data

        var inject : InjectBean
        var bean : BeanDeclaration?

        // init

        init(inject : InjectBean) {
            self.inject = inject
        }

        // override

        override func connect(_ loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            if inject.id != nil {
                bean = try loader.context.getDeclarationById(inject.id!)
            }
            else {
                bean = try loader.context.getCandidate(type)
            }

            loader.dependency(bean!, before: beanDeclaration)
        }

        override func get(_ environment: Environment) throws -> Any {
            return try bean!.getInstance(environment)
        }

        override func getType() -> Any.Type {
            return bean!.clazz!
        }
    }

    class EmbeddedBean : ValueHolder {
        // MARK: instance data

        var bean : BeanDeclaration

        // init

        init(bean : BeanDeclaration) {
            self.bean = bean
        }

        // override

        override func collect(_ loader : Environment.Loader, beanDeclaration : BeanDeclaration) throws -> Void {
            try loader.context.define(bean)
        }

        override func connect(_ loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            loader.dependency(bean, before: beanDeclaration)
        }

        override func get(_ environment: Environment) throws -> Any {
            return try bean.getInstance(environment)
        }

        override func getType() -> Any.Type {
            return bean.clazz!
        }
    }

    class Value : ValueHolder {
        // MARK: instance data

        var value : Any

        // init

        init(value : Any) {
            self.value = value
        }

        // TODO

        func isNumberType(_ type : Any.Type) -> Bool {
            if type == Int8.self {
                return true
            }
            else if type == UInt8.self {
                return true
            }
            else if type == Int16.self {
                return true
            }
            else if type == UInt16.self {
                return true
            }
            else if type == Int32.self {
                return true
            }
            else if type == UInt32.self {
                return true
            }
            else if type == Int64.self {
                return true
            }
            else if type == UInt64.self {
                return true
            }
            else if type == Int.self {
                return true
            }
            else if type == Float.self {
                return true
            }
            else if type == Double.self {
                return true
            }


            return false
        }

        // move somewhere else...
        func coerceNumber(_ value: Any, type: Any.Type) throws -> (value:Any, success:Bool) {
            if isNumberType(type) {
                let conversion = StandardConversionFactory.instance.findConversion(type(of: value), targetType: type)

                if conversion != nil {
                    return (try conversion!(object: value), true)
                }
            }

            return (value, false)
        }

        // override

        override func resolve(_ loader : Environment.Loader, type : Any.Type) throws -> ValueHolder {
            if type != type(of: value) {
                // check if we can coerce numbers...

                let coercion = try coerceNumber(value, type: type)

                if coercion.success {
                    value = coercion.value
                }
                else {
                    throw EnvironmentErrors.typeMismatch(message: "could not convert a \(type(of: value) ) into a \(type)")
                }
            }

            return  self
        }

        override func get(_ environment: Environment) throws -> Any {
            return value
        }

        override func getType() -> Any.Type {
            return type(of: value)
        }
    }

    class PlaceHolder : ValueHolder {
        // MARK: instance data

        var value : String

        // init

        init(value : String) {
            self.value = value
        }

        // override

        override func resolve(_ loader : Environment.Loader, type : Any.Type) throws -> ValueHolder {
            // replace placeholders first...

            value = try loader.resolve(value)

            var result : Any = value;

            // check for conversions

            if type != String.self {
                if let conversion = StandardConversionFactory.instance.findConversion(String.self, targetType: type) {
                    do {
                        result = try conversion(object: value)
                    }
                            catch ConversionErrors.conversionException( _, let targetType, _) {
                        throw ConversionErrors.conversionException(value: value, targetType: targetType, context: "")//[\(origin!.line):\(origin!.column)]")
                    }
                }
                else {
                    throw EnvironmentErrors.typeMismatch(message: "no conversion applicable between String and \(type)")
                }
            }
            // done

            return Value(value: result)
        }
    }
    
    open class PropertyDeclaration : Declaration {
        // MARK: instance data
        
        var name  : String = ""
        var value : ValueHolder?
        var property : BeanDescriptor.PropertyDescriptor?
        
        // functions
        
        func resolveProperty(_ beanDeclaration : BeanDeclaration, loader: Environment.Loader) throws -> Void  {
            property = beanDeclaration.bean.findProperty(name)
            
            if property == nil {
                throw EnvironmentErrors.unknownProperty(property: name, bean: beanDeclaration)
            }
        }
        
        func collect(_ beanDeclaration : BeanDeclaration, environment: Environment, loader: Environment.Loader) throws -> Void {
            if beanDeclaration.clazz != nil { // abstract classes
                try resolveProperty(beanDeclaration, loader: loader)
            }

            try value!.collect(loader, beanDeclaration: beanDeclaration)
        }
        
        func connect(_ beanDeclaration : BeanDeclaration, loader : Environment.Loader) throws -> Void {
            if property == nil {
                // HACK...dunno why...
                try resolveProperty(beanDeclaration, loader: loader)
            }

            try value!.connect(loader, beanDeclaration: beanDeclaration, type: property!.getPropertyType())
        }
        
        func resolve(_ loader : Environment.Loader) throws -> Any? {
            return try value = value!.resolve(loader, type: property!.getPropertyType())
        }

        func get(_ environment: Environment) throws -> Any? {
            return try value!.get(environment)
        }

        func getType() -> Any.Type {
            return value!.getType()
        }
    }

    // default scopes

    open class PrototypeScope : AbstractBeanScope {
        // MARK: init

        override init() {
            super.init(name: "prototype")
        }

        // MARK: override AbstractBeanScope

        open override func get(_ bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
            return try factory.create(bean)
        }
    }

    open class SingletonScope : AbstractBeanScope {
        // MARK: init

        override init() {
            super.init(name: "singleton")
        }

        // MARK: override AbstractBeanScope

        open override func prepare(_ bean : Environment.BeanDeclaration, factory : BeanFactory) throws {
            if !bean.lazy {
                try get(bean, factory: factory)
            }
        }

        open override func get(_ bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
            if bean.singleton == nil {
                bean.singleton = try factory.create(bean)
            }

            return bean.singleton!
        }
    }

    class BeanFactoryScope : BeanScope {
        // MARK: instance data

        let declaration : Environment.BeanDeclaration
        let environment: Environment

        // init

        init(declaration : Environment.BeanDeclaration, environment: Environment) {
            self.declaration = declaration
            self.environment = environment
        }

        // BeanScope

        var name : String {
            get {
                return "does not matter"
            }
        }

        func prepare(_ bean : Environment.BeanDeclaration, factory : BeanFactory) throws {
            // noop
        }

        func get(_ bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
            if let factoryBean = try declaration.getInstance(environment) as? FactoryBean {
                return try environment.runPostProcessors(try factoryBean.create())
            }

            fatalError("cannot happen")
        }

        func finish() {
            // noop
        }
    }

    open class Loader {
        // local classes

        class Dependency : Equatable {
            // MARK: instance data

            var declaration : Environment.BeanDeclaration
            var successors : [Dependency] = []
            var index : Int? = nil
            var lowLink : Int = 0
            var inCount = 0

            // init

            init(declaration : Environment.BeanDeclaration) {
                self.declaration = declaration
            }

            // methods

            func addSuccessor(_ dependency: Dependency) -> Void {
                successors.append(dependency)
                dependency.inCount += 1
            }
        }

        // MARK: instance data

        var context: Environment
        var loading = false
        var dependencyList : [Dependency] = []
        var dependencies = IdentityMap<Environment.BeanDeclaration, Dependency>()
        var resolver : Resolver? = nil

        // init

        init(context: Environment) {
            self.context = context
        }

        // MARK: public

        func resolve(_ string : String) throws -> String {
            var result = string

            if let range = string.range(of: "${") {
                result = string[string.startIndex..<range.lowerBound]

                let eq  = string.range(of: "=", range: range.lowerBound..<string.endIndex)
                let end = string.range(of: "}", options: .backwards, range: range.lowerBound..<string.endIndex)

                if eq != nil {
                    let key = string[range.upperBound ..< eq!.lowerBound]

                    let resolved = try resolver!(key)

                    if (Tracer.ENABLED) {
                        Tracer.trace("inject.configuration", level: .high, message: "resolve configuration key \(key) = \(String(describing: resolved))")
                    }

                    if  resolved != nil {
                        result += resolved!
                    }
                    else {
                        result += try resolve(string[eq!.upperBound..<end!.lowerBound])
                    }
                }
                else {
                    let key = string[range.upperBound ..< end!.lowerBound]
                    let resolved = try resolver!(key)!

                    if (Tracer.ENABLED) {
                        Tracer.trace("inject.configuration", level: .high, message: "resolve configuration key \(key) = \(resolved)")
                    }

                    result += resolved
                } // else

                result += try resolve(string[end!.upperBound..<string.endIndex])
            } // if

            return result
        }

        func setup() throws -> Void {
            // local function

            func resolveConfiguration(_ key: String) throws -> String? {
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

        // MARK: internal

        func getDependency(_ bean : Environment.BeanDeclaration) -> Dependency {
            var dependency = dependencies[bean]
            if dependency == nil {
                dependency = Dependency(declaration: bean)

                dependencyList.append(dependency!)
                dependencies[bean] = dependency!
            }

            return dependency!
        }

        func dependency(_ bean : Environment.BeanDeclaration, before : Environment.BeanDeclaration) {
            getDependency(bean).addSuccessor(getDependency(before))
        }

        func addDeclaration(_ declaration : Environment.BeanDeclaration) throws -> Environment.BeanDeclaration {
            // add

            let dependency = Dependency(declaration: declaration)

            dependencies[declaration] = dependency
            dependencyList.append(dependency)

            return declaration
        }

        func sortDependencies(_ dependencies : [Dependency]) throws -> Void {
            // local functions

            func detectCycles() -> [[Environment.BeanDeclaration]] {
                // closure state

                var index = 0
                var stack: [Dependency] = []
                var cycles: [[Environment.BeanDeclaration]] = []

                // local func

                func traverse(_ dependency: Dependency) {
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

                // done

                return cycles
            }

            // sort

            var stack = [Dependency]()
            for dependency in dependencyList {
                if dependency.inCount == 0 {
                    stack.append(dependency)
                }
            } // for

            var count = 0
            while !stack.isEmpty {
                let dependency = stack.removeFirst()

                dependency.index = count

                //print("\(index): \(dependency.declaration.bean!.clazz)")

                for successor in dependency.successors {
                    successor.inCount -= 1
                    if successor.inCount == 0 {
                        stack.append(successor)
                    }
                } // for

                count += 1
            } // while

            // if something is left, we have a cycle!

            if count < dependencyList.count {
                let cycles = detectCycles()

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

                throw EnvironmentErrors.cylicDependencies(message: builder.toString())
            }
        }

        func load() throws -> Environment {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .high, message: "load \(context.name)")
            }

            loading = true

            try setup()

            // collect

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .high, message: "collect beans")
            }

            for dependency in dependencyList {
                try dependency.declaration.collect(context, loader: self) // define
            }

            // connect

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .high, message: "connect beans")
            }

            for dependency in dependencyList {
                try dependency.declaration.connect(self)
            }

            // sort

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .high, message: "sort beans")
            }

            try sortDependencies(dependencyList)

            // and resort local beans

            context.localBeans.sort(by: {dependencies[$0]!.index! < dependencies[$1]!.index!})

            // resolve

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .high, message: "resolve beans")
            }

            for bean in context.localBeans {
                //let bean = dependency.declaration

                try bean.resolve(self)
                try bean.prepare(self)
            } // for

            // done

            return context
        }
    }

    class EnvironmentPostProcessor: NSObject, EnvironmentAware, BeanPostProcessor {
        // MARK: instance data

        var injector : Injector
        var _environment: Environment?
        var environment: Environment? {
            get {
                return _environment
            }
            set {
                _environment = newValue
            }
        }

        // init

        // needed by the BeanDescriptor
        override init() {
            self.injector = Injector()
            super.init()
        }

        init(environment: Environment) {
            self.injector = environment.injector
            self._environment = environment


            super.init()
        }

        // BeanPostProcessor

        func process(_ instance : AnyObject) throws -> AnyObject {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .high, message: "default post process a \"\(type(of: instance))\"")
            }

            // inject

            try injector.inject(instance, context: environment!)

            // check protocols

            // Bean

            if let bean = instance as? Bean {
                try bean.postConstruct()
            }

            // EnvironmentAware

            if var environmentAware = instance as? EnvironmentAware {
                environmentAware.environment = environment!
            }

            // done

            return instance
        }
    }

    // MARK: static data

    static let LOGGER = LogManager.getLogger(forClass: Environment.self)

    // MARK: instance data

    var traceOrigin = false
    var name : String = ""
    var loader : Loader?
    var parent : Environment? = nil
    var injector : Injector
    var configurationManager : ConfigurationManager
    var byType = [ObjectIdentifier : ArrayOf<BeanDeclaration>]()
    var byId = [String : BeanDeclaration]()
    var postProcessors = [BeanPostProcessor]()
    var scopes = [String:BeanScope]()
    var localBeans = [BeanDeclaration]()

    var singletonScope = SingletonScope()
    
    // MARK: init

    public init(name: String, parent : Environment? = nil, traceOrigin : Bool = false) throws {
        self.name = name
        self.traceOrigin = traceOrigin

        if parent != nil {
            self.parent = parent
            self.injector = parent!.injector
            self.configurationManager = parent!.configurationManager
            //self.singletonScope = parent!.singletonScope
            self.scopes = parent!.scopes

            self.byType = parent!.byType
            self.byId = parent!.byId

            loader = Loader(context: self)
        }
        else {
            // injector

            injector = Injector()

            // configuration manager

            configurationManager = try ConfigurationManager(scope: Scope.WILDCARD)

            // default scopes

            registerScope(PrototypeScope())
            registerScope(singletonScope)

            // default injections

            injector.register(BeanInjection())
            injector.register(ConfigurationValueInjection(configurationManager: configurationManager))

            // set loader here in order to prevent exception due to frozen environment..

            loader = Loader(context: self)

            // default post processor

            try define(bean(EnvironmentPostProcessor(environment: self))) // should be the first bean!

            // add initial bean declarations so that constructed objects can also refer to those instances

            try define(bean(injector))
            try define(bean(configurationManager))
        }
    }

    // MARK: public

    /// load a xl configuration file
    /// - Parameter data: a `NSData` object referencing the config file
    open func loadXML(_ data : Data) throws -> Self {
        try XMLEnvironmentLoader(environment: self)
           .parse(data)

        return self
    }

    /// startup validates all defined beans and creates all singletons in advance
    /// - Returns: self
    /// - Throws: any errors during setup
    open func startup() throws -> Self  {
        if loader != nil {
            // check parent

            if parent != nil {
                try parent!.validate()

                inheritFrom(parent!)
            }

            Environment.LOGGER.info("startup environment \(name)")

            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .high, message: "startup \(name)")
            }

            // load

            try loader!.load()

            loader = nil // prevent double loading...
        } // if

        return self
    }

    /// register a named scope
    // - Parameter scope: the `BeanScope`
    open func registerScope(_ scope : BeanScope) -> Void {
        scopes[scope.name] = scope
    }

    // MARK: fluent interface

    /// Return a named scope
    /// - Parameter scope: the scope name
    /// - Throws: an error if the scope is not defined
    open func scope(_ scope : String) throws -> BeanScope {
        return try getScope(scope)
    }

    /// create a `BeanDeclaration` based on a already constructed object
    /// - Parameter instance: the corresponding instance
    /// - Parameter id: an optional id
    /// - Returns: the new `BeanDeclaration`
    open func bean(_ instance : AnyObject, id : String? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration(instance: instance)

        if id != nil {
            result.id = id
        }

        if traceOrigin {
            result.origin = Origin(file: file, line: line, column: column)
        }

        return result
    }

    /// create a `BeanDeclaration`
    /// - Parameter className: the name of the bean class
    /// - Parameter id: an optional id
    /// - Parameter lazy: the lazy attribute. default is `false`
    /// - Parameter abstract: the abstract attribute. default is `false`
    /// - Returns: the new `BeanDeclaration`
    open func bean(_ className : String, id : String? = nil, lazy : Bool = false, abstract : Bool = false, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        if traceOrigin {
            result.origin = Origin(file: file, line: line, column: column)
        }

        result.lazy = lazy
        result.abstract = abstract

        result.clazz = try Classes.class4Name(className)

        return result
    }

    /// create a `BeanDeclaration`
    /// - Parameter clazz: the bean class
    /// - Parameter id: an optional id
    /// - Parameter lazy: the lazy attribute. default is `false`
    /// - Parameter abstract:t he abstract attribute. default is `false`
    /// - Parameter factory: a factory function that will return a new instance of the specific type
    /// - Returns: the new `BeanDeclaration`
    open func bean<T>(_ clazz : T.Type, id : String? = nil, lazy : Bool = false, abstract : Bool = false, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, factory : (() throws -> T)? = nil) throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        if traceOrigin {
           result.origin = Origin(file: file, line: line, column: column)
        }

        result.lazy = lazy
        result.abstract = abstract

        if factory != nil {
            result.factory = FactoryFactory<T>(factory: factory!)
        }

        if let anyClass = clazz as? AnyClass {
            result.clazz = anyClass

        }
        else {
            throw EnvironmentErrors.exception(message: "only classes are accepted, got \(clazz)")
        }

        return result
    }

    /// return a `Settings` instance tha can be used to define configuration values
    /// - Returns: a new `Settings` instance
    open func settings(_ file: String = #file, function: String = #function, line: Int = #line) -> Settings {
        return Settings(configurationManager: self.configurationManager, url: file + " " + function + " line: " + String(line))
    }

    /// This class collects manual configuration values

    open class Settings : AbstractConfigurationSource {
        // MARK: instance data

        var items = [ConfigurationItem]()

        // MARK: init

        init(configurationManager : ConfigurationManager, url: String) {
            super.init(configurationManager: configurationManager, url: url)
        }

        // MARK:fluent interface

        open func setValue(_ namespace : String = "", key : String, value : Any) -> Self {
            items.append(ConfigurationItem(
                    fqn: FQN(namespace: namespace, key: key),
                    type: type(of: value),
                    value: value,
                    source: url
                    ))

            return self
        }

        // MARK: implement ConfigurationSource

        override open func load(_ configurationManager : ConfigurationManager) throws -> Void {
            for item in items {
                try configurationManager.configurationAdded(item, source: self)
            }
        }
    }

    /// define configuration values
    /// - Parameter settings: the object that contains configuration values
    open func define(_ settings : Settings) throws -> Self {
        try configurationManager.addSource(settings)

        return self
    }

    /// defines the specified `BeanDeclaration`
    /// - Returns: self
    open func define(_ declaration : Environment.BeanDeclaration) throws -> Self {
        // fix scope if not available

        if declaration.scope == nil {
            declaration.scope = singletonScope
        }

        // pass to loader if set

        if loader != nil {
            try loader!.addDeclaration(declaration)
        }
        else { for line in Thread.callStackSymbols {print(line)}
            throw EnvironmentErrors.exception(message: "environment is frozen")
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

    // MARK: internal

    func inheritFrom(_ parent : Environment) {
        if (Tracer.ENABLED) {
            Tracer.trace("inject.loader", level: .high, message: "inherit from \(parent.name)")
        }

        self.postProcessors = parent.postProcessors

        // patch EnvironmentAware

        for declaration in parent.localBeans {
            if var environmentAware = declaration.singleton as? EnvironmentAware { // does not make sense for beans other than singletons...
                environmentAware.environment = self
            }
        }
    }

    func validate() throws {
        if loader != nil && !loader!.loading {
            try startup()
        }
    }

    func getScope(_ name : String) throws -> BeanScope {
        let scope = scopes[name]
        if scope == nil {
            throw EnvironmentErrors.unknownScope(scope: name, context: "")
        }
        else {
            return scope!
        }
    }
    
    func rememberId(_ declaration : Environment.BeanDeclaration) throws -> Void {
        if let id = declaration.id {
            if byId[id] == nil {
                byId[id] = declaration
            }
            else {
                throw EnvironmentErrors.ambiguousBeanById(id: id, context: "")
            }
        }
    }

    func rememberType(_ declaration : Environment.BeanDeclaration) throws -> Void {
        // remember by type for injections
        
        var clazz : AnyClass?;
        if let valueFactory = declaration.factory as? ValueFactory {
            clazz = type(of: valueFactory.object)
        }
        else {
            clazz = declaration.clazz // may be nil in case of a inherited bean!
        }

        // is that a factory bean?

        if clazz is FactoryBean.Type {
            let target : AnyClass? = declaration.target
            if target == nil {
                fatalError("missing target");
            }

            // include artificial bean declaration with special scope

            let bean = BeanDeclaration()

            bean.scope = BeanFactoryScope(declaration : declaration, environment: self)
            bean.requires(bean: declaration)
            bean.clazz = target

            // remember

            try rememberType(bean)
        } // if
        
        if clazz != nil && !declaration.abstract {
            let declarations = byType[ObjectIdentifier(clazz!)]
            if declarations != nil {
                declarations!.append(declaration)
            }
            else {
                byType[ObjectIdentifier(clazz!)] = ArrayOf<Environment.BeanDeclaration>(values: declaration)
            }
        }
    }

    func getCandidate(_ type : Any.Type) throws -> Environment.BeanDeclaration {
        let candidates = getBeanDeclarationsByType(try BeanDescriptor.forType(type))
        
        if candidates.count == 0 {
            throw EnvironmentErrors.noCandidateForType(type: type)
        }
        if candidates.count > 1 {
            throw EnvironmentErrors.ambiguousCandidatesForType(type: type)
        }
        else {
            return candidates[0]
        }
    }
    
    func runPostProcessors(_ instance : AnyObject) throws -> AnyObject {
        var result = instance

        // inject
        
        if (Tracer.ENABLED) {
            Tracer.trace("inject.runtime", level: .high, message: "run post processors on a \"\(type(of: result))\"")
        }

        for processor in postProcessors {
            result = try processor.process(result)
        }

        return result
    }
    
    func getDeclarationById(_ id : String) throws -> Environment.BeanDeclaration {
        let declaration = byId[id]
        
        if declaration == nil {
            throw EnvironmentErrors.unknownBeanById(id: id, context: "")
        }
        
        return declaration!
    }

    open func getBeanDeclarationsByType(_ type : Any.Type) -> [Environment.BeanDeclaration] {
        return getBeanDeclarationsByType(try! BeanDescriptor.forType(type))
    }

    open func getBeanDeclarationsByType(_ bean : BeanDescriptor) -> [Environment.BeanDeclaration] {
        // local func

        func collect(_ bean : BeanDescriptor, candidates : inout [Environment.BeanDeclaration]) -> Void {
            let localCandidates = byType[ObjectIdentifier(bean.type)]

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

        var result : [Environment.BeanDeclaration] = []

        collect(bean, candidates: &result)

        return result
    }

    // MARK: public

    /// Create a string report of all registered bean definitions
    /// - Returns: the report
    open func report() -> String {
        let builder = StringBuilder()

        builder.append("### ENVIRONMENT \(name) REPORT\n")

        for bean in localBeans {
            bean.report(builder)
        }

        return builder.toString()
    }

    /// return an array of all bean instances of a given type
    /// - Parameter type: the bean type
    /// - Returns: the array of instances
    /// - Throws: any errors

    open func getBeansByType<T>(_ type : T.Type) throws -> [T] {
        let declarations = getBeanDeclarationsByType(type)
        var result : [T] = []
        for declaration in declarations {
            if !declaration.abstract {
                result.append(try declaration.getInstance(self) as! T)
            }
        }

        return result
    }

    /// return a bean given the type and an optional id
    /// - Parameter type: the type
    /// - Parameter id: an optional id
    /// - Returns: the instance
    /// - Throws: Any error
    open func getBean<T>(_ type : T.Type, byId id : String? = nil) throws -> T {
        try validate()

        if id != nil {
            if let bean = self.byId[id!] {
                return try bean.getInstance(self) as! T
            }
            else {
                throw EnvironmentErrors.unknownBeanById(id: id!, context: "")
            }
        }
        else {
            let result = getBeanDeclarationsByType(try BeanDescriptor.forType(type))
            
            if result.count == 0 {
                throw EnvironmentErrors.unknownBeanByType(type: type)
            }
            else if result.count > 1 {
                throw EnvironmentErrors.ambiguousBeanByType(type: type)
            }
            else {
                return try result[0].getInstance(self) as! T
            }

        }
    }

    /// return a bean given the type and an optional id ( without generic parameters )
    /// - Parameter type: the type
    /// - Parameter id: an optional id
    /// - Returns: the instance
    /// - Throws: Any error
    open func getBean(_ type : Any.Type, byId id : String? = nil) throws -> AnyObject {
        try validate()

        if id != nil {
            if let bean = self.byId[id!] {
                return try bean.getInstance(self) 
            }
            else {
                throw EnvironmentErrors.unknownBeanById(id: id!, context: "")
            }
        }
        else {
            let result = getBeanDeclarationsByType(try BeanDescriptor.forType(type))

            if result.count == 0 {
                throw EnvironmentErrors.unknownBeanByType(type: type )
            }
            else if result.count > 1 {
                throw EnvironmentErrors.ambiguousBeanByType(type: type )
            }
            else {
                return try result[0].getInstance(self)
            }
        }
    }
    
    open func inject(_ object : AnyObject) throws -> Void {
        try validate()

        try injector.inject(object, context: self)
    }

    /// return the `ConfigurationManager` of this environment
    /// - Returns: the `ConfigurationManager`
    open func getConfigurationManager() -> ConfigurationManager {
        return configurationManager
    }

    /// Add a new configuration source
    /// - Parameter source: a `ConfigurationSource`
    /// - Returns: self
    open func addConfigurationSource(_ source: ConfigurationSource) throws -> Environment {
        try configurationManager.addSource(source)

        return self
    }

    /// return a configuration value
    /// - Parameter type: the expected type
    /// - Parameter namespace: the namespace
    /// - Parameter key: the key
    /// - Parameter defaultValue: the optional default value
    /// - Parameter scope: the optional scope
    /// - Returns: the value
    /// - Throws: any possible error
    open func getConfigurationValue<T>(_ type : T.Type, namespace : String = "", key : String, defaultValue: T? = nil, scope : Scope? = nil) throws -> T {
        return try configurationManager.getValue(type, namespace: namespace, key: key, defaultValue: defaultValue, scope: scope)
    }
    
    // MARK: implement BeanFactory
    
    open func create(_ bean : Environment.BeanDeclaration) throws -> AnyObject {
        return try bean.create(self)
    }
}

func ==(lhs: Environment.Loader.Dependency, rhs: Environment.Loader.Dependency) -> Bool {
    return lhs === rhs
}
