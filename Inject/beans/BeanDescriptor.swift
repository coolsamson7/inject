
//
//  BeanDescriptor.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// `BeanDescriptor` stores information on the internal structure of classes, covering
/// * super- and subclasses
/// * properties including their types
open class BeanDescriptor : CustomStringConvertible {
    // MARK: static data
    
    fileprivate static var beans = [ObjectIdentifier:BeanDescriptor]()

    // MARK: class functions
    
    /// Return the appropriate bean descriptor for the specific class
    /// - Parameter clazz: the corresponding class
    /// - Returns: the `BeanDescriptor` instance for the particular class
    open class func forClass(_ clazz: AnyClass) throws -> BeanDescriptor {
        if let bean = beans[ObjectIdentifier(clazz)] {
            return bean
        }
        else {
            return try BeanDescriptor(type: clazz)
        }
    }

    /// Return the appropriate bean descriptor for the specific type
    /// - Parameter type: the type
    /// - Returns: the `BeanDescriptor` instance for the particular class
    open class func forType(_ type: Any.Type) throws -> BeanDescriptor {
        if let bean = beans[ObjectIdentifier(type)] {
            return bean
        }
        else {
            return try BeanDescriptor(type: type)
        }
    }

    /// Return the appropriate bean descriptor for the specific object type
    /// - Parameter object: the object
    /// - Returns: the `BeanDescriptor` instance for the particular object
    open class func forInstance(_ object: AnyObject) throws -> BeanDescriptor {
        if let bean = beans[ObjectIdentifier(type(of: object))] {
            return bean
        }
        else {
            return try BeanDescriptor(instance: object)
        }
    }

    /// Return the appropriate bean descriptor for the specific class name
    /// - Parameter clazz: the corresponding class name
    /// - Returns: the `BeanDescriptor` instance for the particular class
    open class func forClass(_ clazz: String) throws -> BeanDescriptor {
        return try forClass(try Classes.class4Name(clazz))
    }

    // MARK: internal class functions

    open class func findBeanDescriptor(_ type: Any.Type) -> BeanDescriptor? {
        return beans[ObjectIdentifier(type)]
    }

    // internal

    fileprivate func createInstance4(_ clazz : AnyClass) throws -> AnyObject {
        if let initializable = clazz as? Initializable.Type {
            return initializable.init()
        }
        else {
            throw EnvironmentErrors.exception(message: "cannot create a \(Classes.className(clazz))")
        }
    }

    // MARK: inner classes
    
    open class PropertyDescriptor : CustomStringConvertible {
        // MARK: instance data
        
        var bean: BeanDescriptor
        var name: String
        var type: Any.Type
        var elementType : Any.Type?
        var factory : Factory
        var optional = false
        var index: Int
        var overallIndex: Int
        var autowired = false
        var inject : Inject?
        var constraint : TypeDescriptor? = nil
        
        // MARK: constructor

        public init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, elementType: Any.Type?, factory : @escaping Factory, optional : Bool) {
            self.bean = bean
            self.name = name
            self.type = type
            self.elementType = elementType
            self.optional = optional
            self.factory = factory
            self.index = index
            self.overallIndex = overallIndex
        }
        
        // MARK: public
        
        open func getPropertyType() -> Any.Type {
            return type;
        }

        open func isOptional() -> Bool {
            return optional
        }

        open func getBean() -> BeanDescriptor {
            return bean
        }
        
        open func getIndex() -> Int {
            return index
        }
        
        open func getOverallIndex() -> Int {
            return overallIndex
        }
        
        open func getName() -> String {
            return name
        }
        
        open func isAttribute() -> Bool {
            return true;
        }

        open func isArray() -> Bool {
            return elementType != nil // what about other container types: set, dictionary, etc.
        }

        open func getElementType() -> Any.Type {
            return elementType!
        }

        open func getFactory() -> Factory {
            return factory
        }
        
        open func get(_ object: AnyObject!) -> Any? {
            return object.value(forKey: name)
        }
        
        open func set(_ object: AnyObject, value: Any?) throws -> Void {
            if value != nil {
                object.setValue(box(value!), forKey: name)
            }
            else {
                if optional {
                    object.setValue(nil, forKey: name)
                }
                else {
                    throw BeanDescriptorErrors.cannotSetNil(message: "nil not allowed for property \(self.name)")
                }
            }
        }
        
        open func isValid(_ value : Any) -> Bool {
            if type(of: value) == self.type { // is assignable?
                if constraint != nil {
                    return constraint!.isValid(value)
                }
                else {
                    return true
                }
            }
            
            else {
                return false
            }
        }
        
        open func type(_ type : TypeDescriptor) -> Self {
            if type.getType() == self.type {
                self.constraint = type
            }
            else {
                fatalError("type constraint does not match base type")
            }
            
            return self
        }
        
        open func autowire(_ value : Bool = true) -> Self {
            autowired = value
            
            if value {
                inject(InjectBean())
            }

            return self
        }
        
        open func inject(_ inject : Inject) -> Self {
            self.inject = inject
            
            if inject is InjectBean {
                autowired = true
            }

            return self
        }

        // MARK: internal

        // take car of boxing...ugh

        func box(_ value: Any) -> AnyObject {
            if value is Int64 {
                return NSNumber(value: value as! Int64 as Int64)
            }

            if value is UInt64 {
                return NSNumber(value: value as! UInt64 as UInt64)
            }

            if value is Int32 {
                return NSNumber(value: value as! Int32 as Int32)
            }

            if value is UInt32 {
                return NSNumber(value: value as! UInt32 as UInt32)
            }

            if value is Int16 {
                return NSNumber(value: value as! Int16 as Int16)
            }

            if value is UInt16 {
                return NSNumber(value: value as! UInt16 as UInt16)
            }

            if value is Int8 {
                return NSNumber(value: value as! Int8 as Int8)
            }

            if value is UInt8 {
                return NSNumber(value: value as! UInt8 as UInt8)
            }

            return value as AnyObject // Strings...
        }
        
        // MARK: implement CustomStringConvertible
        
        open var description: String {
            get {
                return "{\(name)\", type: \(type), optional: \(optional)}"
            }
        }
    }
    
    open class AttributeDescriptor: PropertyDescriptor {
        // override
        
        override init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, elementType: Any.Type?, factory : @escaping Factory, optional: Bool) {
            super.init(bean: bean, name: name, index: index, overallIndex: overallIndex, type: type, elementType: elementType, factory: factory, optional: optional);
        }
    }

    /// currently not used...
    open class RelationDescriptor : PropertyDescriptor {
        // MARK: instance data
        
        var target: BeanDescriptor;
        
        // override
        
        init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, factory : @escaping Factory, optional: Bool)  {
            target = try! BeanDescriptor.forClass(type as! AnyClass)
            
            super.init(bean: bean, name: name, index: index, overallIndex: overallIndex, type: type, elementType: type /* TODO */, factory: factory, optional: optional);
        }
        
        override open func isAttribute() -> Bool {
            return false;
        }
    }
    
    // MARK: instance data
    
    internal var type : Any.Type
    internal var superBean: BeanDescriptor?
    internal var allProperties: [PropertyDescriptor]! = [PropertyDescriptor]()
    internal var ownProperties: [PropertyDescriptor]! = [PropertyDescriptor]()
    internal var properties: [String:PropertyDescriptor]! = [String: PropertyDescriptor]()
    internal var directSubBeans = [BeanDescriptor]()
    internal var protocols = [BeanDescriptor]()

    // MARK: constructor

    public init(type: Any.Type) throws {
        self.type = type

        if (Tracer.ENABLED) {
            Tracer.trace("inject.beans", level: .high, message: "create descriptor for \(type)")
        }

        // register

        BeanDescriptor.beans[ObjectIdentifier(type)] = self

        // and analyze

        if let clazz = type as? AnyClass {
            let instance = try createInstance4(clazz)

            try analyze(Mirror(reflecting: instance), instance: instance)
        }
    }

    public init(instance: AnyObject, mirror : Mirror? = nil) throws {
        if (Tracer.ENABLED) {
            Tracer.trace("inject.beans", level: .high, message: "create descriptor for \(type(of: instance))")
        }

        let _mirror = mirror != nil ? mirror! : Mirror(reflecting: instance)

        self.type = _mirror.subjectType

        // register

        BeanDescriptor.beans[ObjectIdentifier(type)] = self

        // and analyze

        try analyze(_mirror, instance: instance)
    }
    
    // private
    
    fileprivate func analyze(_ mirror : Mirror, instance : AnyObject) throws {
        // check super mirror

        if let superMirror = mirror.superclassMirror {
            if let superClass = superMirror.subjectType as? AnyClass {
                superBean = BeanDescriptor.beans[ObjectIdentifier(superClass)] != nil ?  BeanDescriptor.beans[ObjectIdentifier(superClass)]  : try BeanDescriptor(instance: instance, mirror: superMirror)

                superBean!.directSubBeans.append(self)

                // add inherited properties

                for property in superBean!.allProperties {
                    allProperties.append(property)

                    properties[property.name] = property;
                }
            }
            else {
                // hmmm....what could this be?
            }
        }

        // local stuff

        var startIndex = properties.count

        // analyze properties

        if let displayStyle = mirror.displayStyle {
            if displayStyle == .class {
                // analyze properties
                
                var index = 0
                for case let (label?, value) in mirror.children {
                    let property = analyzeProperty(label, value: value, index: index, overallIndex: startIndex)
                    
                    ownProperties.append(property)
                    allProperties.append(property)
                    
                    properties[property.name] = property;
                    
                    index += 1
                    startIndex += 1
                } // for
            }
        }

        // this is a hack since swift does not include something like a static initializer
        // ( and i am obviously too stupid to call a class func :-) )

        if let beanDescriptorInitializer = instance as? BeanDescriptorInitializer {
            if type(of: instance) == self.type {
                beanDescriptorInitializer.initializeBeanDescriptor(self)
            }
        }
    }

    fileprivate class func missingFactory() -> Any {
        fatalError("no factory implemented")
    }

    fileprivate func analyzeProperty(_ name : String, value: Any, index : Int, overallIndex : Int) -> AttributeDescriptor {
        let mirror : Mirror  = Mirror(reflecting: value)
        var type = mirror.subjectType
        var optional = false
        var elementType : Any.Type? = nil
        var factory : Factory = BeanDescriptor.missingFactory

        // unwrap optional type

        if let optionalType = value as? OptionalType {
            type = optionalType.wrappedType()
            optional = true
        }

        // extract array type

        if let array = value as? ArrayType {
            elementType = array.elementType()
            factory = array.factory()
        }

        return AttributeDescriptor(bean: self, name: name, index: index, overallIndex: overallIndex, type: type, elementType: elementType, factory: factory, optional: optional)
    }

    // MARK: public
    
    open func getType() -> Any.Type {
        return type
    }

    open func isClass() -> Bool {
        return type is AnyClass
    }

    open func getClass() -> AnyClass {
        return type as! AnyClass
    }

    open func getSuperBean() -> BeanDescriptor? {
        return superBean
    }

    open func getSubBeans() -> [BeanDescriptor] {
        return directSubBeans
    }
    
    open func create() throws -> AnyObject {
        if let initializable = type as? Initializable.Type {
            return initializable.init()
        }
        else {
            throw BeanDescriptorErrors.exception(message: "cannot create a \(type)")
        }
    }
    
    open func getProperties(_ local : Bool = false) -> [PropertyDescriptor] {
        return local ? ownProperties : allProperties
    }
    
    open func getProperty(_ name: String) throws -> PropertyDescriptor {
        let property =  properties[name]
        if property == nil {
            throw BeanDescriptorErrors.unknownProperty(message: "unknown property \(type).\(name)")
        }
        return property!
    }
    
    open func findProperty(_ name: String) -> PropertyDescriptor? {
        return properties[name]
    }

    open func implementedBy(_ bean : BeanDescriptor) -> Self {
        if !directSubBeans.contains(where: {$0 === bean}) {
            directSubBeans.append(bean)
        } // if

        return self
    }

    open func implements(_ types : Any.Type...) throws -> Self {
        for type in types {
            if let clazz = type as? AnyClass {
                throw BeanDescriptorErrors.exception(message: "implements expects a protocol, got a class \(clazz)")
            }

            let protocolDescriptor = try! BeanDescriptor.forType(type)

            if !protocols.contains(where: {$0 === protocolDescriptor}) {
                protocols.append(protocolDescriptor) // local only

                protocolDescriptor.implementedBy(self)
            } // if
        }

        return self
    }
    
    // subscript
    
    open subscript(name: String) -> PropertyDescriptor {
        get {
            return try! getProperty(name)
        }
    }
    
    // CustomStringConvertible
    
    open var description: String {
        get {
            let builder = StringBuilder()
            
            builder.append("bean(\(type)) {\n")
            
            for property in allProperties {
                builder.append("\t\(property.bean.type).\(property.name): \(property.type)")
                if property.optional {
                    builder.append("?")
                }

                builder.append("\n")
            }
            
            builder.append("}")
            
            return builder.toString()
        }
    }
}

