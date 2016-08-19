
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
public class BeanDescriptor : CustomStringConvertible {
    // MARK: static data
    
    private static var beans = [ObjectIdentifier:BeanDescriptor]()

    // MARK: class functions
    
    /// Return the appropriate bean descriptor for the specific class
    /// - Parameter clazz: the corresponding class
    /// - Returns: the `BeanDescriptor` instance for the particular class
    public class func forClass(clazz: AnyClass) throws -> BeanDescriptor {
        if let bean = beans[ObjectIdentifier(clazz)] {
            return bean
        }
        else {
            return try BeanDescriptor(type: clazz)
        }
    }

    /// Return the appropriate bean descriptor for the specific class name
    /// - Parameter clazz: the corresponding class name
    /// - Returns: the `BeanDescriptor` instance for the particular class
    public class func forClass(clazz: String) throws -> BeanDescriptor {
        return try forClass(try Classes.class4Name(clazz))
    }

    // MARK: internal class functions

    public class func findBeanDescriptor(type: Any.Type) -> BeanDescriptor? {
        return beans[ObjectIdentifier(type)]
    }

    // internal

    private func createInstance4(clazz : AnyClass) throws -> AnyObject {
        if let initializable = clazz as? Initializable.Type {
            return initializable.init()
        }
        else {
            throw EnvironmentErrors.Exception(message: "cannot create a \(Classes.className(clazz))")
        }
    }

    // MARK: inner classes
    
    public class PropertyDescriptor : CustomStringConvertible {
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
        
        // MARK: constructor
        
        init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, elementType: Any.Type?, factory : Factory, optional : Bool) {
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
        
        public func getPropertyType() -> Any.Type {
            return type;
        }

        public func isOptional() -> Bool {
            return optional
        }

        public func getBean() -> BeanDescriptor {
            return bean
        }
        
        public func getIndex() -> Int {
            return index
        }
        
        public func getOverallIndex() -> Int {
            return overallIndex
        }
        
        public func getName() -> String {
            return name
        }
        
        public func isAttribute() -> Bool {
            return true;
        }

        public func isArray() -> Bool {
            return elementType != nil // what about other container types: set, dictionary, etc.
        }

        public func getElementType() -> Any.Type {
            return elementType!
        }

        public func getFactory() -> Factory {
            return factory
        }
        
        public func get(object: AnyObject!) -> Any? {
            return object.valueForKey(name)
        }
        
        public func set(object: AnyObject, value: Any?) throws -> Void {
            if value != nil {
                object.setValue(box(value!), forKey: name)
            }
            else {
                if optional {
                    object.setValue(nil, forKey: name)
                }
                else {
                    throw BeanDescriptorErrors.CannotSetNil(message: "nil not allowed for property \(self.name)")
                }
            }
        }
        
        public func autowire(value : Bool = true) {
            autowired = value
            
            if value {
                inject(InjectBean())
            }
        }
        
        public func inject(inject : Inject) {
            self.inject = inject
            
            if inject is InjectBean {
                autowired = true
            }
        }

        // MARK: internal

        // take car of boxing...ugh

        func box(value: Any) -> AnyObject {
            if value is Int64 {
                return NSNumber(longLong: value as! Int64)
            }

            if value is UInt64 {
                return NSNumber(unsignedLongLong: value as! UInt64)
            }

            if value is Int32 {
                return NSNumber(int: value as! Int32)
            }

            if value is UInt32 {
                return NSNumber(unsignedInt: value as! UInt32)
            }

            if value is Int16 {
                return NSNumber(short: value as! Int16)
            }

            if value is UInt16 {
                return NSNumber(unsignedShort: value as! UInt16)
            }

            if value is Int8 {
                return NSNumber(char: value as! Int8)
            }

            if value is UInt8 {
                return NSNumber(unsignedChar: value as! UInt8)
            }

            return value as! AnyObject // Strings...
        }
        
        // CustomStringConvertible
        
        public var description: String {
            get {
                return "{\(name)\", type: \(type), optional: \(optional)}"
            }
        }
    }
    
    public class AttributeDescriptor: PropertyDescriptor {
        // override
        
        override init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, elementType: Any.Type?, factory : Factory, optional: Bool) {
            super.init(bean: bean, name: name, index: index, overallIndex: overallIndex, type: type, elementType: elementType, factory: factory, optional: optional);
        }
    }

    /// currently not used...
    public class RelationDescriptor : PropertyDescriptor {
        // MARK: instance data
        
        var target: BeanDescriptor;
        
        // override
        
        init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, factory : Factory, optional: Bool)  {
            target = try! BeanDescriptor.forClass(type as! AnyClass)
            
            super.init(bean: bean, name: name, index: index, overallIndex: overallIndex, type: type, elementType: type /* TODO */, factory: factory, optional: optional);
        }
        
        override public func isAttribute() -> Bool {
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
    
    // MARK: constructor
    
    init(type: Any.Type) throws {
        self.type = type

        if (Tracer.ENABLED) {
            Tracer.trace("inject.beans", level: .HIGH, message: "create descriptor for \(type)")
        }

        // register

        BeanDescriptor.beans[ObjectIdentifier(type)] = self

        // and analyze

        if let clazz = type as? AnyClass {
            let instance = try createInstance4(clazz)

            try analyze(Mirror(reflecting: instance), instance: instance)
        }
    }

    init(instance: AnyObject, mirror : Mirror? = nil) throws {
        if (Tracer.ENABLED) {
            Tracer.trace("inject.beans", level: .HIGH, message: "create descriptor for \(instance.dynamicType)")
        }

        let _mirror = mirror != nil ? mirror! : Mirror(reflecting: instance)

        self.type = _mirror.subjectType

        // register

        BeanDescriptor.beans[ObjectIdentifier(type)] = self

        // and analyze

        try analyze(_mirror, instance: instance)
    }
    
    // private
    
    private func analyze(mirror : Mirror, instance : AnyObject) throws {
        // check super mirror

        if let superMirror = mirror.superclassMirror() {
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
            if displayStyle == .Class {
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
            if instance.dynamicType == self.type {
                beanDescriptorInitializer.initializeBeanDescriptor(self)
            }
        }
    }

    private class func missingFactory() -> Any {
        fatalError("no factory implemented")
    }

    private func analyzeProperty(name : String, value: Any, index : Int, overallIndex : Int) -> AttributeDescriptor {
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
    
    public func getType() -> Any.Type {
        return type
    }

    public func isClass() -> Bool {
        return type is AnyClass
    }

    public func getClass() -> AnyClass {
        return type as! AnyClass
    }

    public func getSuperBean() -> BeanDescriptor? {
        return superBean
    }

    public func getSubBeans() -> [BeanDescriptor] {
        return directSubBeans
    }
    
    public func create() throws -> AnyObject {
        if let initializable = type as? Initializable.Type {
            return initializable.init()
        }
        else {
            throw BeanDescriptorErrors.Exception(message: "cannot create a \(type)")
        }
    }
    
    public func getProperties(local : Bool = false) -> [PropertyDescriptor] {
        return local ? ownProperties : allProperties
    }
    
    public func getProperty(name: String) throws -> PropertyDescriptor {
        let property =  properties[name]
        if property == nil {
            throw BeanDescriptorErrors.UnknownProperty(message: "unknown property \(type).\(name)")
        }
        return property!
    }
    
    public func findProperty(name: String) -> PropertyDescriptor? {
        return properties[name]
    }
    
    // subscript
    
    public subscript(name: String) -> PropertyDescriptor {
        get {
            return try! getProperty(name)
        }
    }
    
    // CustomStringConvertible
    
    public var description: String {
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

