//
//  Environment.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public typealias Resolver = (key : String) throws -> String?

/// this factory creates instances by calling a specified function
class FactoryFactory<T> : BeanFactory {
    // MARK: instance data

    var factory : () -> T

    // MARK: init

    init(factory : () -> T ) {
        self.factory = factory
    }

    // MARK: implement BeanFactory

    func create(bean : Environment.BeanDeclaration) throws -> AnyObject {
        return factory() as! AnyObject
    }
}

/// ´Environment´is the central class that collects bean infromations and takes care of their lifecycle
public class Environment: BeanFactory {
    // MARK: local classes

    /// this factory calls the default constructor of the given class
    class DefaultConstructorFactory : BeanFactory {
        // static data

        static var instance = DefaultConstructorFactory()

        // MARK: implement BeanFactory

        func create(declaration: BeanDeclaration) throws -> AnyObject {
            return try declaration.bean!.create()
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

        func create(bean : BeanDeclaration) throws -> AnyObject {
            return object
        }
    }
    
    public class Declaration : NSObject, OriginAware {
        // MARK: instance data
        
        var _origin : Origin?
        
        // MARK: implement OriginAware
        
        var origin : Origin? {
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
    /// - the class
    /// - the scope: "singleton", "prototype" or custom. "singleton" is the default
    /// - lazy attribute. The defualt is `false`
    /// - optional id of a parent bean if, that defines common attributes that will be inherited
    /// - properties
    /// - the target class for factory beans
    public class BeanDeclaration : Declaration {
        // MARK: instance data
        
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
            self.bean = try! BeanDescriptor.forClass(instance.dynamicType)
        }

        /// create a new `BeanDeclaration`
        override init() {
            super.init()
        }
        
        // MARK: fluent stuff

        /// set the class of this bean declaration
        /// - Parameter clazz: the class name
        /// - Returns: self
        public func clazz(clazz : String) throws -> BeanDeclaration {
            self.bean = try BeanDescriptor.forClass(clazz)

            return self
        }

        /// set the id of this bean declaration
        /// - Parameter id: the id
        /// - Returns: self
        public func id(id : String) -> BeanDeclaration {
            self.id = id

            return self
        }

        /// set the `lazy' attribute of this bean declaration
        /// - Parameter lazy: if `true`, the instance will be created whenever it is requested for the first time
        /// - Returns: self
        public func lazy(lazy : Bool = true) -> BeanDeclaration {
            self.lazy = lazy

            return self
        }

        /// set the `abstract' attribute of this bean declaration
        /// - Parameter abstract: if `true`, the instance will not be craeted but serves only as a template for inherited beans
        /// - Returns: self
        public func abstract(abstract : Bool = true) -> BeanDeclaration {
            self.abstract = abstract

            return self
        }

        /// set the scope of this bean declaration
        /// - Parameter scope: the scope
        /// - Returns: self
        public func scope(scope : BeanScope) -> BeanDeclaration {
            self.scope = scope

            return self
        }

        /// specifies that this bean needs to be constructed after another bean
        /// - Parameter depends: the id of the bean which needs to be constructed first
        /// - Returns: self
        public func dependsOn(depends : String) -> BeanDeclaration {
            self.dependsOn = BeanDeclaration(id: depends)

            return self
        }

        /// specifies a bean that will serve as a template
        /// - Parameter parent: the id of the parent bean
        /// - Returns: self
        public func parent(parent : String) -> BeanDeclaration {
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
        public func property(name: String, value : Any? = nil, ref : String? = nil, resolve : String? = nil, bean : BeanDeclaration? = nil, inject : InjectBean? = nil) -> BeanDeclaration {
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
        public func target(clazz : AnyClass) throws -> BeanDeclaration {
            self.target = try BeanDescriptor.forClass(clazz)

            return self
        }

        public func property(property: PropertyDeclaration) -> BeanDeclaration {
            properties.append(property)

            return self
        }
        
        // MARK: internal

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
        
        func inheritFrom(parent : BeanDeclaration, loader: Environment.Loader) throws -> Void  {
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
        
        func collect(environment: Environment, loader: Environment.Loader) throws -> Void {
            for property in properties {
                try property.collect(self, environment: environment, loader: loader)
            }
        }
        
        func connect(loader : Environment.Loader) throws -> Void {
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
        
        func resolve(loader : Environment.Loader) throws -> Void {
            for property in properties {
                try property.resolve(loader)

                if !checkTypes(property.getType(), expected: property.property!.getPropertyType()) {
                    throw EnvironmentErrors.TypeMismatch(message: " property \(Classes.className(bean!.clazz)).\(property.name) expected a \(property.property!.getPropertyType()) got \(property.getType())")
                }
            }
        }

        func prepare(loader : Environment.Loader) throws -> Void {
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
        
        func getInstance(environment: Environment) throws -> AnyObject {
            return try scope!.get(self, factory: environment)
        }
        
        func create(environment: Environment) throws -> AnyObject {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .HIGH, message: "create instance of \(bean!.clazz)")
            }
            
            let result = try factory.create(self) // MARK: constructor, value, etc
            
            // set properties
            
            for property in properties {
                let beanProperty = property.property!
                let resolved = try property.get(environment)

                if resolved != nil {
                    if (Tracer.ENABLED) {
                        Tracer.trace("inject.runtime", level: .FULL, message: "set \(Classes.className(bean!.clazz)).\(beanProperty.getName()) = \(resolved!)")
                    }

                    try beanProperty.set(result, value: resolved)
                } // if
            }

            // run processors
            
            return try environment.runPostProcessors(result);
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
        func collect(loader : Environment.Loader, beanDeclaration : BeanDeclaration) throws -> Void {
            // noop
        }

        func connect(loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            // noop
        }

        func resolve(loader : Environment.Loader, type : Any.Type) throws -> ValueHolder {
            return  self
        }

        func get(environment: Environment) throws -> Any {
            fatalError("\(self.dynamicType).get is abstract")
        }

        func getType() -> Any.Type {
            fatalError("\(self.dynamicType).getType is abstract")
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

        override func connect(loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            ref = try loader.context.getDeclarationById(ref.id!) // replace with real declaration

            loader.dependency(ref, before: beanDeclaration)
        }


        override func get(environment: Environment) throws -> Any {
            return try ref.getInstance(environment)
        }

        override func getType() -> Any.Type {
            return ref.bean!.clazz
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

        override func connect(loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            if inject.id != nil {
                bean = try loader.context.getDeclarationById(inject.id!)
            }
            else {
                bean = try loader.context.getCandidate(type as! AnyClass)
            }

            loader.dependency(bean!, before: beanDeclaration)
        }

        override func get(environment: Environment) throws -> Any {
            return try bean!.getInstance(environment)
        }

        override func getType() -> Any.Type {
            return bean!.bean!.clazz
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

        override func collect(loader : Environment.Loader, beanDeclaration : BeanDeclaration) throws -> Void {
            try loader.context.define(bean)
        }

        override func connect(loader : Environment.Loader, beanDeclaration : BeanDeclaration, type : Any.Type) throws -> Void {
            loader.dependency(bean, before: beanDeclaration)
        }

        override func get(environment: Environment) throws -> Any {
            return try bean.getInstance(environment)
        }

        override func getType() -> Any.Type {
            return bean.bean!.clazz
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

        func isNumberType(type : Any.Type) -> Bool {
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
        func coerceNumber(value: Any, type: Any.Type) throws -> (value:Any, success:Bool) {
            if isNumberType(type) {
                let conversion = StandardConversionFactory.instance.findConversion(value.dynamicType, targetType: type)

                if conversion != nil {
                    return (try conversion!(object: value), true)
                }
            }

            return (value, false)
        }

        // override

        override func resolve(loader : Environment.Loader, type : Any.Type) throws -> ValueHolder {
            if type != value.dynamicType {
                // check if we can coerce numbers...

                let coercion = try coerceNumber(value, type: type)

                if coercion.success {
                    value = coercion.value
                }
                else {
                    throw EnvironmentErrors.TypeMismatch(message: "could not convert a \(value.dynamicType ) into a \(type)")
                }
            }

            return  self
        }

        override func get(environment: Environment) throws -> Any {
            return value
        }

        override func getType() -> Any.Type {
            return value.dynamicType
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

        override func resolve(loader : Environment.Loader, type : Any.Type) throws -> ValueHolder {
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
                    throw EnvironmentErrors.TypeMismatch(message: "no conversion applicable between String and \(type)")
                }
            }
            // done

            return Value(value: result)
        }
    }
    
    public class PropertyDeclaration : Declaration {
        // MARK: instance data
        
        var name  : String = ""
        var value : ValueHolder?
        var property : BeanDescriptor.PropertyDescriptor?
        
        // functions
        
        func resolveProperty(beanDeclaration : BeanDeclaration, loader: Environment.Loader) throws -> Void  {
            property = beanDeclaration.bean!.findProperty(name)
            
            if property == nil {
                throw EnvironmentErrors.UnknownProperty(property: name, bean: beanDeclaration)
            }
        }
        
        func collect(beanDeclaration : BeanDeclaration, environment: Environment, loader: Environment.Loader) throws -> Void {
            if beanDeclaration.bean != nil { // abstract classes
                try resolveProperty(beanDeclaration, loader: loader)
            }

            try value!.collect(loader, beanDeclaration: beanDeclaration)
        }
        
        func connect(beanDeclaration : BeanDeclaration, loader : Environment.Loader) throws -> Void {
            if property == nil {
                // HACK...dunno why...
                try resolveProperty(beanDeclaration, loader: loader)
            }

            try value!.connect(loader, beanDeclaration: beanDeclaration, type: property!.getPropertyType())
        }
        
        func resolve(loader : Environment.Loader) throws -> Any? {
            return try value = value!.resolve(loader, type: property!.getPropertyType())
        }

        func get(environment: Environment) throws -> Any? {
            return try value!.get(environment)
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

        public func prepare(bean : Environment.BeanDeclaration, factory : BeanFactory) throws {
            // noop
        }

        public func get(bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
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

        public func prepare(bean : Environment.BeanDeclaration, factory : BeanFactory) throws {
            if !bean.lazy {
                try get(bean, factory: factory)
            }
        }

        public func get(bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
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
        // MARK: instance data

        let declaration : Environment.BeanDeclaration
        let context: Environment

        // init

        init(declaration : Environment.BeanDeclaration, context: Environment) {
            self.declaration = declaration
            self.context = context
        }

        // BeanScope

        var name : String {
            get {
                return "does not matter"
            }
        }

        func prepare(bean : Environment.BeanDeclaration, factory : BeanFactory) throws {
            // noop
        }

        func get(bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject {
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

            func addSuccessor(dependency: Dependency) -> Void {
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

        func resolve(string : String) throws -> String {
            var result = string

            if let range = string.rangeOfString("${", range: string.startIndex..<string.endIndex) {
                result = string[string.startIndex..<range.startIndex]

                let eq  = string.rangeOfString("=", range: range.startIndex..<string.endIndex)
                let end = string.rangeOfString("}", range: range.startIndex..<string.endIndex, options: .BackwardsSearch)

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

        // MARK: internal

        func getDependency(bean : Environment.BeanDeclaration) -> Dependency {
            var dependency = dependencies[bean]
            if dependency == nil {
                dependency = Dependency(declaration: bean)

                dependencyList.append(dependency!)
                dependencies[bean] = dependency!
            }

            return dependency!
        }

        func dependency(bean : Environment.BeanDeclaration, before : Environment.BeanDeclaration) {
            getDependency(bean).addSuccessor(getDependency(before))
        }

        func addDeclaration(declaration : Environment.BeanDeclaration) throws -> Environment.BeanDeclaration {
            // add

            let dependency = Dependency(declaration: declaration)

            dependencies[declaration] = dependency
            dependencyList.append(dependency)

            return declaration
        }

        func sortDependencies(dependencies : [Dependency]) -> [[Environment.BeanDeclaration]] {
            // closure state

            var index = 0
            var stack: [Dependency] = []
            var cycles: [[Environment.BeanDeclaration]] = []

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

            // done

            return cycles
        }

        func load() throws -> Environment {
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

                throw EnvironmentErrors.CylicDependencies(message: builder.toString())
            }
            else {
                // hmmm....tarjan does not sort topologically..let's do that here

                var stack = [Dependency]()
                for dependency in dependencyList {
                    if dependency.inCount == 0 {
                        stack.append(dependency)
                    }
                } // for

                var index = 0
                while !stack.isEmpty {
                    let dependency = stack.removeFirst()

                    dependency.index = index

                    //print("\(index): \(dependency.declaration.bean!.clazz)")

                    for successor in dependency.successors {
                        successor.inCount -= 1
                        if successor.inCount == 0 {
                            stack.append(successor)
                        }
                    } // for

                    index += 1
                }
            }

            // sort according to index

            //dependencyList.sortInPlace({$0.index < $1.index})

            // and resort local beans

            context.localBeans.sortInPlace({dependencies[$0]!.index < dependencies[$1]!.index})

            // resolve

            if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "resolve beans")
            }

            for bean in context.localBeans {
                //let bean = dependency.declaration

                try bean.resolve(self)
                try bean.prepare(self)
            } // for


            /*if (Tracer.ENABLED) {
                Tracer.trace("inject.loader", level: .HIGH, message: "prepare beans")
            }

            for dependency in dependencyList {
                try dependency.declaration.prepare(self)  // instantiate all non lazy singletons, add post processors, etc...
            }*/

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

        func process(instance : AnyObject) throws -> AnyObject {
            if (Tracer.ENABLED) {
                Tracer.trace("inject.runtime", level: .HIGH, message: "default post process a \"\(instance.dynamicType)\"")
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

    // MARK: instance data

    var name : String = ""
    var loader : Loader?
    var parent : Environment? = nil
    var injector : Injector
    var configurationManager : ConfigurationManager
    var byType = IdentityMap<AnyObject,ArrayOf<BeanDeclaration>>()
    var byId = [String : BeanDeclaration]()
    var postProcessors = [BeanPostProcessor]()
    var scopes = [String:BeanScope]()
    var localBeans = [BeanDeclaration]()

    var singletonScope : BeanScope
    
    // MARK: init
    
    init(name: String, parent : Environment? = nil) throws {
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

            try define(BeanDeclaration(instance: EnvironmentPostProcessor(environment: self))) // should be the first bean!
        }
    }

    // MARK: public

    /// load a xl configuration file
    /// - Parameter data: a `NSData` object referencing the config file
    public func loadXML(data : NSData) throws -> Environment {
        try XMLEnvironmentLoader(environment: self)
           .parse(data)

        return self
    }

    /// refresh validates all defined beans and creates all singletons in advance
    /// - Returns: self
    /// - Throws: any errors during setup
    public func refresh() throws -> Environment  {
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

            loader = nil // prevent double loading...
        } // if

        return self
    }

    /// register a named scope
    // - Parameter scope: the ``BeanScope
    public func registerScope(scope : BeanScope) -> Void {
        scopes[scope.name] = scope
    }

    // MARK: fluent interface

    /// Return a named scope
    /// - Parameter scope: the scope name
    /// - Throws: an error if the scope is not defined
    public func scope(scope : String) throws -> BeanScope {
        return try getScope(scope)
    }

    /// create a `BeanDeclaration` based on a already constructed object
    /// - Parameter instance: the corresponding instance
    /// - Parameter id: an optional id
    /// - Returns: the new `BeanDeclaration`
    public func bean(instance : AnyObject, id : String? = nil) -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration(instance: instance)

        if id != nil {
            result.id = id
        }

        return result
    }

    /// create a `BeanDeclaration
    /// - Parameter className: the name of the bean class
    /// - Parameter id: an optional id
    /// - Parameter lazy: the lazy attribute. default is ´false´
    /// - Parameter abstract:t he abstract attribute. default is ´false´
    /// - Returns: the new `BeanDeclaration`
    public func bean(className : String, id : String? = nil, lazy : Bool = false, abstract : Bool = false) throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        result.lazy = lazy
        result.abstract = abstract

        result.bean = try BeanDescriptor.forClass(className)

        return result
    }

    /// create a `BeanDeclaration
    /// - Parameter clazz: the bean class
    /// - Parameter id: an optional id
    /// - Parameter lazy: the lazy attribute. default is ´false´
    /// - Parameter abstract:t he abstract attribute. default is ´false´
    /// - Parameter factory: a factory funtion that will return a new instance of the specific type
    /// - Returns: the new `BeanDeclaration`
    public func bean<T>(clazz : T.Type, id : String? = nil, lazy : Bool = false, abstract : Bool = false, factory : (() -> T)? = nil) throws -> Environment.BeanDeclaration {
        let result = Environment.BeanDeclaration()

        if id != nil {
            result.id = id
        }

        result.lazy = lazy
        result.abstract = abstract

        if factory != nil {
            result.factory = FactoryFactory<T>(factory: factory!)
        }

        result.bean = try BeanDescriptor.forClass(clazz as! AnyClass)

        return result
    }

    /// defines the specified ´BeanDeclaration´
    /// - Returns: self
    public func define(declaration : Environment.BeanDeclaration) throws -> Environment {
        // fix scope if not available

        if declaration.scope == nil {
            declaration.scope = singletonScope
        }

        // pass to loader if set

        if loader != nil {
            try loader!.addDeclaration(declaration)
        }
        else {
            throw EnvironmentErrors.Exception(message: "environment is frozen")
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

    func inheritFrom(parent : Environment) {
        if (Tracer.ENABLED) {
            Tracer.trace("inject.loader", level: .HIGH, message: "inherit from \(parent.name)")
        }

        self.postProcessors = parent.postProcessors

        // nor merge for dictionaries...

        //self.byType = parent.byType
        //self.byId = parent.byId

        // patch EnvironmentAware

        for declaration in parent.localBeans {
            if var environmentAware = declaration.singleton as? EnvironmentAware { // does not make sense for beans other than singletons...
                environmentAware.environment = self
            }
        }
    }

    func validate() throws {
        if loader != nil && !loader!.loading {
            try refresh()
        }
    }

    func getScope(name : String) throws -> BeanScope {
        let scope = scopes[name]
        if scope == nil {
            throw EnvironmentErrors.UnknownScope(scope: name, context: "")
        }
        else {
            return scope!
        }
    }

    
    func rememberId(declaration : Environment.BeanDeclaration) throws -> Void {
        if let id = declaration.id {
            if byId[id] == nil {
                byId[id] = declaration
            }
            else {
                throw EnvironmentErrors.AmbiguousBeanById(id: id, context: "")
            }
        }
    }

    func rememberType(declaration : Environment.BeanDeclaration) throws -> Void {
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
                byType[clazz!] = ArrayOf<Environment.BeanDeclaration>(values: declaration);
            }
        }
    }

    func getCandidate(clazz : AnyClass) throws -> Environment.BeanDeclaration {
        let candidates = getBeanDeclarationsByType(try BeanDescriptor.forClass(clazz))
        
        if candidates.count == 0 {
            throw EnvironmentErrors.NoCandidateForType(type: clazz)
        }
        if candidates.count > 1 {
            throw EnvironmentErrors.AmbiguousCandidatesForType(type: clazz)
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
    
    func getDeclarationById(id : String) throws -> Environment.BeanDeclaration {
        let declaration = byId[id]
        
        if declaration == nil {
            throw EnvironmentErrors.UnknownBeanById(id: id, context: "")
        }
        
        return declaration!
    }

    public func getBeanDeclarationsByType(clazz : AnyClass) -> [Environment.BeanDeclaration] {
        return getBeanDeclarationsByType(try! BeanDescriptor.forClass(clazz))
    }

    public func getBeanDeclarationsByType(bean : BeanDescriptor) -> [Environment.BeanDeclaration] {
        // local func

        func collect(bean : BeanDescriptor, inout candidates : [Environment.BeanDeclaration]) -> Void {
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

        var result : [Environment.BeanDeclaration] = []

        collect(bean, candidates: &result)

        return result
    }

    // MARK: public

    /// Create a string report of all registered bean definitions
    /// - Returns: the report
    public func report() -> String {
        let builder = StringBuilder()

        builder.append("### ENVIRONMENT \(name) REPORT\n")

        for bean in localBeans {
            bean.report(builder)
        }

        return builder.toString()
    }

    /// return an array of all bean instances of a given type
    /// - Parameter clazz: the bean class
    /// - Returns: the array of instances
    /// - Throws: any errors

    public func getBeansByType(clazz : AnyClass) throws -> [AnyObject] {
        let declarations = getBeanDeclarationsByType(clazz)
        var result : [AnyObject] = []
        for declaration in declarations {
            if !declaration.abstract {
                result.append(try declaration.getInstance(self))
            }
        }

        return result
    }

    /// return a bean given the type and an optional id
    /// - Parameter type: the type
    /// - Parameter id: an optional id
    /// - Returns: the instance
    /// - Throws: Any error
    public func getBean<T>(type : T.Type, byId id : String? = nil) throws -> T {
        try validate()

        if id != nil {
            if let bean = self.byId[id!] {
                return try bean.getInstance(self) as! T
            }
            else {
                throw EnvironmentErrors.UnknownBeanById(id: id!, context: "")
            }
        }
        else {
            let result = getBeanDeclarationsByType(try BeanDescriptor.forClass(type as! AnyClass))
            
            if result.count == 0 {
                throw EnvironmentErrors.UnknownBeanByType(type: type as! AnyClass)
            }
            else if result.count > 1 {
                throw EnvironmentErrors.AmbiguousBeanByType(type: type as! AnyClass)
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
    public func getBean(type : AnyClass, byId id : String? = nil) throws -> AnyObject {
        try validate()

        if id != nil {
            if let bean = self.byId[id!] {
                return try bean.getInstance(self) 
            }
            else {
                throw EnvironmentErrors.UnknownBeanById(id: id!, context: "")
            }
        }
        else {
            let result = getBeanDeclarationsByType(try BeanDescriptor.forClass(type ))

            if result.count == 0 {
                throw EnvironmentErrors.UnknownBeanByType(type: type )
            }
            else if result.count > 1 {
                throw EnvironmentErrors.AmbiguousBeanByType(type: type )
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

    /// return the ´ConfigurationManager´ of this environment
    /// - Returns: the ´ConfigurationManager´
    public func getConfigurationManager() -> ConfigurationManager {
        return configurationManager
    }

    /// return a configuration value
    /// - Parameter type: the expected type
    /// - Parameter namespace: the namespace
    /// - Parameter key: the key
    /// - Parameter defaultValue: the optional default value
    /// - Parameter scope: the optional scope
    /// - Returns: the value
    /// - Throws: any possible error
    public func getValue<T>(type : T.Type, namespace : String, key : String, defaultValue: T? = nil, scope : Scope? = nil) throws -> T {
        return try configurationManager.getValue(type, namespace: namespace, key: key, defaultValue: defaultValue, scope: scope)
    }
    
    // MARK: implement BeanFactory
    
    public func create(bean : Environment.BeanDeclaration) throws -> AnyObject {
        return try bean.create(self)
    }
}

func ==(lhs: Environment.Loader.Dependency, rhs: Environment.Loader.Dependency) -> Bool {
    return lhs === rhs
}