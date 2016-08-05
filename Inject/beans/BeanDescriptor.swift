
//
//  BeanDescriptor.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// `BeanDescriptor` stores information on the internal structure of classes, covering
/// - super- and subclasses
/// - properties including their types

public class BeanDescriptor : CustomStringConvertible {
    // MARK: static data
    
    private static var beans = IdentityMap<AnyObject, BeanDescriptor>();
    
    // class methods
    
    ///Return the
    /// - Parameter clazz: the corresponding class
    ///
    /// - Returns: the `BeanDescriptor` instance for the particular class
    public class func forClass(clazz: AnyClass) -> BeanDescriptor {
        if let bean = beans[clazz] {
            return bean;
        }
        else {
            let bean = BeanDescriptor(clazz: clazz);
            
            beans[clazz] = bean;
            
            bean.analyze()
            
            return bean;
        }
    }
    
    public class func forClass(clazz: String) throws -> BeanDescriptor {
        return forClass(try Classes.class4Name(clazz))
    }
    
    // inner classes
    
    public class PropertyDescriptor : CustomStringConvertible {
        // instance data
        
        var bean: BeanDescriptor;
        var name: String;
        var type: Any.Type;
        var optional = false
        var index: Int;
        var overallIndex: Int;
        var autowired = false
        var inject : Inject?
        
        // constructor
        
        init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, optional : Bool) {
            self.bean = bean
            self.name = name
            self.type = type;
            self.optional = optional;
            self.index = index
            self.overallIndex = overallIndex
        }
        
        // public
        
        public func getPropertyType() -> Any.Type {
            return type;
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
        
        public func get(object: AnyObject!) -> Any {
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

        // internal

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
        
        override init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, optional: Bool) {
            super.init(bean: bean, name: name, index: index, overallIndex: overallIndex, type: type, optional: optional);
        }
    }
    
    public class RelationDescriptor: PropertyDescriptor {
        // instance data
        
        var target: BeanDescriptor;
        
        // override
        
        override init(bean: BeanDescriptor, name: String, index: Int, overallIndex: Int, type: Any.Type, optional: Bool) {
            target = BeanDescriptor.forClass(type as! NSObject.Type)
            
            super.init(bean: bean, name: name, index: index, overallIndex: overallIndex, type: type, optional: optional);
        }
        
        override public func isAttribute() -> Bool {
            return false;
        }
        
    }
    
    // instance data
    
    internal var clazz: AnyClass;
    internal var superBean: BeanDescriptor?;
    internal var allProperties: [PropertyDescriptor]! = [PropertyDescriptor]();
    internal var ownProperties: [PropertyDescriptor]! = [PropertyDescriptor]();
    internal var properties: [String:PropertyDescriptor]! = [String: PropertyDescriptor]();
    internal var directSubBeans = [BeanDescriptor]()
    
    // constructor
    
    init(clazz: AnyClass) {
        self.clazz = clazz
    }
    
    // private

    func analyzeProperty(name : String, value: Any, index : Int, overallIndex : Int) -> AttributeDescriptor {
        let mirror : Mirror  = Mirror(reflecting: value)
        var type = mirror.subjectType
        var optional = false
        
        // what the hell?

        if let optionalType = value as? OptionalType {
            type = optionalType.wrappedType()
            optional = true
        }

        //if let array = value as? ArrayType {
        //    print(array.elementType())
        //}
        
        return AttributeDescriptor(bean: self, name: name, index: index, overallIndex: overallIndex, type: type, optional: optional)
    }
    
    private func analyze() {
        // check superclass
        
        if let superClass = clazz.superclass() {
            if superClass != NSObject.self {
                superBean = BeanDescriptor.forClass(superClass)
                
                superBean!.directSubBeans.append(self)
                
                // add inherited properties
                
                for property in superBean!.allProperties {
                    allProperties.append(property)
                    
                    properties[property.name] = property;
                }
            }
        }
        
        var startIndex = properties.count

        // create a sample instance

        let instance  = create();

        // and check the mirror...

        let mirror = Mirror(reflecting: instance)
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

        if let classInitializer = instance as? ClassInitializer {
            classInitializer.initializeClass()
        }

        //print(self)
    }
    
    // public
    
    public func getBeanClass() -> AnyClass {
        return clazz
    }
    
    public func create() -> AnyObject {
        return (clazz as! NSObject.Type).init();
    }
    
    public func getProperties() -> [PropertyDescriptor] {
        return ownProperties;
    }
    
    public func getAllProperties() -> [PropertyDescriptor] {
        return allProperties;
    }
    
    public func getProperty(name: String) throws -> PropertyDescriptor {
        let property =  properties[name];
        if property == nil {
            throw BeanDescriptorErrors.UnknownProperty(message: "unknown property \(clazz).\(name)")
        }
        return property!
    }
    
    public func findProperty(name: String) -> PropertyDescriptor? {
        return properties[name];
    }
    
    // subscript
    
    subscript(name: String) -> PropertyDescriptor {
        get {
            return try! getProperty(name)
        }
    }
    
    // reflection
    
    func get(object: NSObject!, property: String) throws -> Any? {
        return try getProperty(property).get(object);
    }
    
    func set(object: NSObject!, property: String, value: Any?) throws -> Void {
        try getProperty(property).set(object, value: value);
    }
    
    // CustomStringConvertible
    
    public var description: String {
        get {
            let builder = StringBuilder()
            
            builder.append("bean(\(clazz)) {\n")
            
            for (name,property) in properties {
                builder.append("\t").append(name).append(": \(property.type)")
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

