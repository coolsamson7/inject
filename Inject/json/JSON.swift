//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// `JSON` is a class that is able to convert swift objects in json strings and vice versa

public struct Conversions<S,T> {
    // MARK: instance data

    var source2Target : Conversion?
    var target2Source : Conversion?

    var sourceType : Any.Type
    var targetType : Any.Type

    // MARK: init

    init(toTarget: (S) -> T, toSource: (T) -> S) {
        source2Target = { value in toTarget(value as! S)}
        target2Source = { value in toSource(value as! T)}

        sourceType = S.self
        targetType = T.self
    }

    // public

    public func toTarget(source : Any) throws -> Any {
        return source2Target != nil ? try source2Target!(object: source) : source
    }

    public func toSource(target : Any) throws -> Any {
        return target2Source != nil ? try target2Source!(object: target) : target
    }
}
public class JSON {
    // MARK: local classes

    class TypeKey : Hashable {
        // MARK: instance data

        var type : Any.Type

        // init

        init(type : Any.Type) {
            self.type = type
        }

        // MARK: implement Hashable

        var hashValue: Int {
            get {
                return "\(type)".hashValue
            }
        }
    }

    class JSONOperation {
        func resolveWrite(definition : MappingDefinition, last : Bool) throws -> Void {
        }

        func resolveRead(mappers : [TypeKey:Mapper] , mappingDefinition : MappingDefinition) throws -> Void {
        }
    }

    class JSONBuilder {
        var level = 0
        var builder = StringBuilder()

        func increment() -> JSONBuilder {
            level += 1
            return self
        }

        func decrement() -> JSONBuilder {
            level -= 1
            return self
        }

        func indent() -> JSONBuilder {
            builder.append(String(count: level, repeatedValue: Character("\t")))

            return self
        }

        func append(object : String) -> JSONBuilder {
            builder.append(object)

            return self
        }
    }

    class JSONProperty : JSONOperation {
        // instance data

        var property : String
        var json : String
        var deep : Bool
        var source2Target : Conversion? = nil
        var target2Source : Conversion? = nil

        // init

        init(property : String, json: String, deep : Bool = false, source2Target : Conversion? = nil, target2Source : Conversion? = nil) {
            self.deep = deep
            self.property = property
            self.json = json
            self.source2Target = source2Target
            self.target2Source = target2Source
        }

        // override

        override func resolveWrite(definition : MappingDefinition, last: Bool) throws -> Void {
            let bean = try BeanDescriptor.forClass(definition.target[0])

            let prop = try bean.getProperty(property)
            var conversion : MappingConversion? = nil

            if source2Target != nil {
                conversion = MappingConversion(sourceConversion: source2Target!, targetConversion: nil)
            }

            definition.map([MappingDefinition.BeanPropertyAccessor(propertyName: property)], target: [JSONWriteAccessor(propertyName: json, type: prop.getPropertyType(), deep: deep, last: last)], conversion: conversion)
        }

        override func resolveRead(mappers : [TypeKey:Mapper], mappingDefinition : MappingDefinition) throws -> Void {
            let bean = try BeanDescriptor.forClass(mappingDefinition.target[1])

            let prop = try bean.getProperty(property)

            var conversion : MappingConversion? = nil

            if target2Source != nil {
                conversion = MappingConversion(sourceConversion: nil, targetConversion: target2Source!)
            }

            mappingDefinition.map([JSONReadAccessor(mappers: mappers, propertyName: property, json: json, type: prop.getPropertyType(), deep: deep)], target: [MappingDefinition.BeanPropertyAccessor(propertyName: property)], conversion: conversion)
        }
    }

    public class Wildcard {
        func makeOperations(definition : Definition) throws -> Void {
            precondition(false, "\(self.dynamicType).makeOperations() is not implemented")
        }
    }

    public class Properties : Wildcard {
        // MARK: instance data

        var except : [String] = []

        // MARK: public

        public func except(exceptions : String...) -> Self {
            for exception in exceptions {
                except.append(exception)
            }

            return self
        }

        // MARK: implement Qualifier

        override func makeOperations(definition : Definition) throws -> Void {
            let bean = try BeanDescriptor.forClass(definition.clazz)

            for property in bean.getAllProperties() {
                if !except.contains(property.getName()) {
                    definition.operations.append(JSONProperty(property: property.getName(), json: property.getName(), deep : false))
                }
            }
        }
    }

    public class Definition {
        // MARK: instance data

        var clazz : AnyClass
        var operations = [JSONOperation]()

        // MARK: init

        init(clazz : AnyClass) {
            self.clazz = clazz
        }

        // MARK: fluent

        public func map(wildcard : Wildcard) throws -> Self {
            try wildcard.makeOperations(self)

            return self
        }

        public func map(property: String, json: String? = nil, deep: Bool = false) -> Self {
            operations.append(JSONProperty(property: property, json: json != nil ? json! : property, deep : deep))

            return self
        }

        public func map<S,T>(property: String, json: String? = nil, deep: Bool = false, conversions: Conversions<S,T>) -> Self {
            operations.append(JSONProperty(property: property, json: json != nil ? json! : property, deep : deep, source2Target: conversions.source2Target, target2Source: conversions.target2Source))

            return self
        }
    }

    class JSONWriteAccessor : Accessor {
        // MARK: local classes

        class WriteProperty: Property<MappingContext> {
            // MARK: instance data

            var property : String
            var deep : Bool
            var last : Bool

            // MARK: init

            init(property: String, deep : Bool, last : Bool) {
                self.property = property
                self.deep = deep
                self.last = last
            }

            // MARK: override

            override func set(object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
                if let builder = object as? JSONBuilder {
                    builder.append("\n").indent().append("\"\(property)\": ")

                    if value == nil {
                        builder.append("nil")
                    }
                    else {
                        if (deep) {
                            builder.append("{").increment()

                            try context.mapper.map(value as? AnyObject, context: context, target: builder)

                            builder.append("\n").decrement().indent().append("}")
                        }
                        else {
                            if let str: String = value as? String {
                                builder.append("\"\(str)\"")
                            }
                            else {
                                builder.append("\(value!)")
                            }
                        }
                    }

                    if !last {
                        builder.append(",")
                    }
                }
            }
        }

        // MARK: instance data

        var propertyName: String;
        var _deep: Bool
        var last : Bool

        // MARK: init

        init(propertyName: String, type: Any.Type, deep: Bool,  last : Bool) {
            self.propertyName = propertyName;
            self._deep = deep
            self.last = last

            super.init(overrideType: type);
        }

        // MARK: implement Accessor

        override func getName() -> String {
            return "\(propertyName)"
        }

        override func resolve(clazz: Any.Type) throws -> Void {
        }

        override func getType() -> Any.Type {
            return overrideType!
        }

        override func makeTransformerProperty(mode: MappingDefinition.Mode, expectedType: Any.Type?, transformerSourceProperty: Property<MappingContext>?) -> Property<MappingContext> {
            return WriteProperty(property: propertyName, deep: _deep, last: last);
        }

        override func isReadOnly() -> Bool {
            return false;
        }

        override func deep() -> Bool {
            return false
        }

        override func equals(object: AnyObject) -> Bool {
            if let accessor = object as? JSONWriteAccessor {
                return propertyName == accessor.propertyName
            }
            else {
                return false;
            }
        }

        // MARK: implement CustomStringConvertible

        override var description: String {
            return propertyName
        }

    }

    class JSONContainer {
        // MARK: instance data

        var data : [String:AnyObject];

        // MARK: init

        init(data : [String:AnyObject]) {
            self.data = data
        }
    }

    class JSONReadAccessor : Accessor {
        // MARK: local classes

        class ReadProperty: Property<MappingContext> {
            // MARK: instance data

            var property : String
            var json : String
            var type : Any.Type?

            // MARK: init

            init(type : Any.Type?, property: String, json: String) {
                self.type = type
                self.property = property
                self.json = json
            }

            // MARK: override

            override func get(object: AnyObject!, context: MappingContext) throws -> Any? {
                if let data = object as? JSONContainer {
                    return data.data[json]
                }
                else {
                    precondition(false, "expected container")
                }
            }
        }

        class ReadDeepProperty : ReadProperty {
            // MARK: instance data

            var mapper : Mapper

            // MARK: init

            init(mapper : Mapper, type : Any.Type?, property: String, json : String) {
                self.mapper = mapper

                super.init(type : type, property: property, json: json)
            }

            // MARK: override

            override func get(object: AnyObject!, context: MappingContext) throws -> Any? {
                var result = try super.get(object, context: context)

                if let dictionary = result as? [String:AnyObject]  {
                    let container = JSONContainer(data: dictionary)

                    result = try mapper.map(container, direction: .SOURCE_2_TARGET)!
                }

                return result;
            }
        }

        // MARK: instance data

        var propertyName: String
        var json : String
        var _deep: Bool
        var mappers : [TypeKey:Mapper]

        // MARK: init

        init(mappers : [TypeKey:Mapper], propertyName: String, json: String, type: Any.Type, deep: Bool) {
            self.propertyName = propertyName
            self.json = json
            self._deep = deep
            self.mappers = mappers

            super.init(overrideType: type);
        }

        // MARK: implement Accessor

        override func getName() -> String {
            return "\(propertyName)"
        }

        override func resolve(clazz: Any.Type) throws -> Void {
        }

        override func getType() -> Any.Type {
            return overrideType!
        }

        override func makeTransformerProperty(mode: MappingDefinition.Mode, expectedType: Any.Type?, transformerSourceProperty: Property<MappingContext>?) -> Property<MappingContext> {
            if _deep && expectedType != nil {
                let mapper = mappers[TypeKey(type: expectedType!)]
                if (mapper == nil) {
                    fatalError("unknown mapper for type \(expectedType!)")
                }

                return ReadDeepProperty(mapper: mapper!, type: expectedType, property: propertyName, json: json)
            }
            else {
                return ReadProperty(type: expectedType, property: propertyName, json: json)
            }
        }

        override func isReadOnly() -> Bool {
            return false
        }

        override func deep() -> Bool {
            return false
        }

        override func equals(object: AnyObject) -> Bool {
            if let accessor = object as? JSONReadAccessor {
                return propertyName == accessor.propertyName
            }
            else {
                return false;
            }
        }

        // MARK: implement CustomStringConvertible

        override var description: String {
            return propertyName
        }

    }

    // MARK: class functions

    public class func mapping(clazz : AnyClass) -> Definition {
        return Definition(clazz: clazz);
    }

    public class func properties() -> Properties {
        return Properties();
    }

    // MARK: instance data

    var toJSON : Mapper;
    var initialFromMapper : Mapper?;

    // MARK: init

    init(mappings: Definition...) throws {
        // write

        var mappingDefinitions = [MappingDefinition]();

        for mapping in mappings {
            let mappingDefinition = MappingDefinition(sourceBean:  mapping.clazz, targetBean: JSONBuilder.self)

            var index = 0
            for operation in mapping.operations {
                try operation.resolveWrite(mappingDefinition, last: index == mapping.operations.count - 1)

                index += 1
            }

            mappingDefinitions.append(mappingDefinition)
        }

        toJSON = Mapper(mappings: mappingDefinitions)

        // read

        var mappers = [TypeKey:Mapper]()

        // create mappers first so we can pass them to deep mappings

        for mapping in mappings {
            // we need different mappers since the source object is always the same :-(

            let mapper = Mapper(mappings: [MappingDefinition(sourceBean: JSONContainer.self, targetBean: mapping.clazz)])

            if initialFromMapper == nil {
                initialFromMapper = mapper
            }

            mappers[TypeKey(type: mapping.clazz)] = mapper
        }

        // initialize definitions

        for mapping in mappings {
            // retrieve mapper

            let mapper = mappers[TypeKey(type: mapping.clazz)]!
            let mappingDefinition = mapper.definitions![0]

            // resolve

            for operation in mapping.operations {
                try operation.resolveRead(mappers, mappingDefinition: mappingDefinition)
            }
        }
    }

    /// convert the specified object into a json string
    /// - Parameter source: the object
    /// - Returns: the json representation
    public func asJSON(source : AnyObject) throws -> String {
        let result = JSONBuilder();

        result.append("{")
        result.increment()

        try toJSON.map(source, direction: .SOURCE_2_TARGET, target: result)

        result.decrement();
        result.append("\n}")

        return result.builder.toString()
    }

    /// convert a json string into an object
    /// - Parameter json: the json string
    /// - Returns: the object
    public func fromJSON(json : String) throws -> AnyObject {
        let data = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

        let jsonData = try JSONContainer(data: NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String:AnyObject]);

        return try initialFromMapper!.map(jsonData, direction: .SOURCE_2_TARGET)!
    }

    /// convert a json string into an object
    /// - Parameter json: the json string
    /// - Returns: the object
    public func fromJSON<T>(type : T.Type, json : String) throws -> T {
        let data = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

        let jsonData = try JSONContainer(data: NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String:AnyObject]);

        return try initialFromMapper!.map(jsonData, direction: .SOURCE_2_TARGET) as! T
    }
}

func ==(lhs: JSON.TypeKey, rhs: JSON.TypeKey) -> Bool {
    return lhs.type == rhs.type
}