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

    init(toTarget: @escaping (S) -> T, toSource: @escaping (T) -> S) {
        source2Target = { value in toTarget(value as! S)}
        target2Source = { value in toSource(value as! T)}

        sourceType = S.self
        targetType = T.self
    }

    // public

    public func toTarget(_ source : Any) throws -> Any {
        return source2Target != nil ? try source2Target!(object: source) : source
    }

    public func toSource(_ target : Any) throws -> Any {
        return target2Source != nil ? try target2Source!(object: target) : target
    }
}
open class JSON {
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
        func resolveWrite(_ definition : MappingDefinition, last : Bool) throws -> Void {
        }

        func resolveRead(_ mappers : [TypeKey:Mapper] , mappingDefinition : MappingDefinition) throws -> Void {
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
            builder.append(String(repeating: "\t", count: level))

            return self
        }

        func append(_ object : String) -> JSONBuilder {
            builder.append(object)

            return self
        }
    }

    class BeanArrayAppenderAccessor : MappingDefinition.BeanPropertyAccessor {
        // local classes

        class BeanArrayAppenderProperty : BeanProperty<MappingContext> {
            // MARK: init

            override init(property: BeanDescriptor.PropertyDescriptor) {
                super.init(property: property)
            }

            // MARK: override Property

            override func set(_ object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
                if (Tracer.ENABLED) {
                    Tracer.trace("beans", level: .high, message: "set property \"\(property.name)\" to \(String(describing: value))")
                }

                /*let array = value as! Array<Any>
                var targetArray = property.get(object)// as! ArrayType

                print(targetArray as? Array)
                for element in array {
                    //targetArray._append(element)
                }*/

                try property.set(object, value: value)
            }
        }

        // init

        override init(propertyName : String) {
            super.init(propertyName: propertyName)
        }

        // override

        override func makeTransformerProperty(_ mode: MappingDefinition.Mode, expectedType: Any.Type?, transformerSourceProperty: Property<MappingContext>?) -> Property<MappingContext> {
            return BeanArrayAppenderProperty(property: property!)
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

        override func resolveWrite(_ definition : MappingDefinition, last: Bool) throws -> Void {
            let bean = try BeanDescriptor.forClass(definition.target[0])

            let prop = try bean.getProperty(property)
            var conversion : MappingConversion? = nil

            if source2Target != nil {
                conversion = MappingConversion(sourceConversion: source2Target!, targetConversion: nil)
            }

            definition.map(
                    [MappingDefinition.BeanPropertyAccessor(propertyName: property)],
                    target: [
                            JSONWriteAccessor(
                               property: prop,
                               propertyName: json,
                               type: prop.getPropertyType(),
                               deep: deep,
                               last: last)
                    ],
                    conversion: conversion)
        }

        override func resolveRead(_ mappers : [TypeKey:Mapper], mappingDefinition : MappingDefinition) throws -> Void {
            let bean = try BeanDescriptor.forClass(mappingDefinition.target[1])

            let prop = try bean.getProperty(property)

            var conversion : MappingConversion? = nil

            if target2Source != nil {
                conversion = MappingConversion(sourceConversion: nil, targetConversion: target2Source!)
            }

            if prop.isArray() {
                mappingDefinition.map(
                        [JSONReadAccessor(mappers: mappers, property: prop, propertyName: property, json: json, type: prop.getPropertyType(), deep: deep)],
                        target: [ BeanArrayAppenderAccessor(propertyName: property) ],
                        conversion: conversion
                        )
            }
            else {
                mappingDefinition.map(
                        [JSONReadAccessor(mappers: mappers, property: prop, propertyName: property, json: json, type: prop.getPropertyType(), deep: deep)],
                        target: [ MappingDefinition.BeanPropertyAccessor(propertyName: property) ],
                        conversion: conversion
                        )
            }
        }
    }

    open class Wildcard {
        func makeOperations(_ definition : Definition) throws -> Void {
            precondition(false, "\(type(of: self)).makeOperations() is not implemented")
        }
    }

    open class Properties : Wildcard {
        // MARK: instance data

        var except : [String] = []

        // MARK: public

        open func except(_ exceptions : String...) -> Self {
            for exception in exceptions {
                except.append(exception)
            }

            return self
        }

        // MARK: implement Qualifier

        override func makeOperations(_ definition : Definition) throws -> Void {
            let bean = try BeanDescriptor.forClass(definition.clazz)

            for property in bean.getProperties() {
                if !except.contains(property.getName()) {
                    definition.operations.append(JSONProperty(property: property.getName(), json: property.getName(), deep : false))
                }
            }
        }
    }

    open class Definition {
        // MARK: instance data

        var clazz : AnyClass
        var operations = [JSONOperation]()

        // MARK: init

        init(clazz : AnyClass) {
            self.clazz = clazz
        }

        // MARK: fluent

        open func map(_ wildcard : Wildcard) throws -> Self {
            try wildcard.makeOperations(self)

            return self
        }

        open func map(_ property: String, json: String? = nil, deep: Bool = false) -> Self {
            operations.append(JSONProperty(property: property, json: json != nil ? json! : property, deep : deep))

            return self
        }

        open func map<S,T>(_ property: String, json: String? = nil, deep: Bool = false, conversions: Conversions<S,T>) -> Self {
            operations.append(JSONProperty(property: property, json: json != nil ? json! : property, deep : deep, source2Target: conversions.source2Target, target2Source: conversions.target2Source))

            return self
        }
    }

    class JSONWriteAccessor : Accessor {
        // MARK: local classes

        class WriteProperty: Property<MappingContext> {
            // MARK: instance data

            var property : BeanDescriptor.PropertyDescriptor
            var json : String
            var deep : Bool
            var last : Bool

            // MARK: init

            init(property : BeanDescriptor.PropertyDescriptor, json: String, deep : Bool, last : Bool) {
                self.property = property
                self.json = json
                self.deep = deep
                self.last = last
            }

            // MARK: override

            override func set(_ object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
                if let builder = object as? JSONBuilder {
                    builder.append("\n").indent().append("\"\(json)\": ")

                    if value == nil {
                        builder.append("null")
                    }
                    else {
                        if (deep) {
                            if property.isArray() {
                                builder.append("[").increment()

                                let array = value! as! Array<AnyObject> // hmmm is there a better way, generic magic?
                                var first = true
                                for element in array {
                                    if !first {
                                        builder.append(",\n").indent().append("{").increment()
                                    }
                                    else {
                                        builder.append("\n").indent().append("{").increment()
                                    }

                                    try context.mapper.map(element, context: context, target: builder)

                                    builder.append("\n").decrement().indent().append("}")

                                    first = false
                                }


                                builder.append("\n").decrement().indent().append("]")
                            }
                            else { // plain object
                                builder.append("{").increment()

                                try context.mapper.map(value as? AnyObject, context: context, target: builder)

                                builder.append("\n").decrement().indent().append("}")
                            }
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

        var propertyName: String
        var property : BeanDescriptor.PropertyDescriptor
        var _deep: Bool
        var last : Bool

        // MARK: init

        init(property : BeanDescriptor.PropertyDescriptor, propertyName: String, type: Any.Type, deep: Bool,  last : Bool) {
            self.property = property
            self.propertyName = propertyName
            self._deep = deep
            self.last = last

            super.init(overrideType: type);
        }

        // MARK: implement Accessor

        override func getName() -> String {
            return "\(propertyName)"
        }

        override func resolve(_ clazz: Any.Type) throws -> Void {
        }

        override func getType() -> Any.Type {
            return overrideType!
        }

        override func makeTransformerProperty(_ mode: MappingDefinition.Mode, expectedType: Any.Type?, transformerSourceProperty: Property<MappingContext>?) -> Property<MappingContext> {
            return WriteProperty(property: property, json: propertyName, deep: _deep, last: last);
        }

        override func isReadOnly() -> Bool {
            return false;
        }

        override func deep() -> Bool {
            return false
        }

        override func equals(_ object: AnyObject) -> Bool {
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

            override func get(_ object: AnyObject!, context: MappingContext) throws -> Any? {
                if let data = object as? JSONContainer {
                    return data.data[json]
                }
                else {
                    return nil // should not happen
                }
            }
        }

        class ReadArrayProperty : ReadProperty {
            // MARK: instance data

            var mapper : Mapper

            // MARK: init

            init(mapper : Mapper, type : Any.Type?, property: String, json : String) {
                self.mapper = mapper

                super.init(type : type, property: property, json: json)
            }

            // MARK: override

            override func get(_ object: AnyObject!, context: MappingContext) throws -> Any? {
                let result = try super.get(object, context: context)

                var resultArray : [AnyObject] = []
                if let array = result as? [[String:AnyObject]]  {
                    for dictionary in array {
                        let container = JSONContainer(data: dictionary)

                        let element = try mapper.map(container, direction: .source_2_TARGET)!

                        resultArray.append(element)
                    } // for
                } // if

                return resultArray;
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

            override func get(_ object: AnyObject!, context: MappingContext) throws -> Any? {
                var result = try super.get(object, context: context)

                if let dictionary = result as? [String:AnyObject]  {
                    let container = JSONContainer(data: dictionary)

                    result = try mapper.map(container, direction: .source_2_TARGET)!
                }

                return result;
            }
        }

        // MARK: instance data

        var property : BeanDescriptor.PropertyDescriptor
        var propertyName: String
        var json : String
        var _deep: Bool
        var mappers : [TypeKey:Mapper]

        // MARK: init

        init(mappers : [TypeKey:Mapper], property : BeanDescriptor.PropertyDescriptor, propertyName: String, json: String, type: Any.Type, deep: Bool) {
            self.property = property
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

        override func resolve(_ clazz: Any.Type) throws -> Void {
        }

        override func getType() -> Any.Type {
            return overrideType!
        }

        override func makeTransformerProperty(_ mode: MappingDefinition.Mode, expectedType: Any.Type?, transformerSourceProperty: Property<MappingContext>?) -> Property<MappingContext> {
            if _deep && expectedType != nil {
                if property.isArray() {
                    let mapper = mappers[TypeKey(type: property.getElementType())]
                    if (mapper == nil) {
                        fatalError("unknown mapper for type \(expectedType!)")
                    }

                    return ReadArrayProperty(mapper: mapper!, type: expectedType, property: propertyName, json: json)
                }
                else {
                    let mapper = mappers[TypeKey(type: expectedType!)]
                    if (mapper == nil) {
                        fatalError("unknown mapper for type \(expectedType!)")
                    }

                    return ReadDeepProperty(mapper: mapper!, type: expectedType, property: propertyName, json: json)
                }
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

        override func equals(_ object: AnyObject) -> Bool {
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

    open class func mapping(_ clazz : AnyClass) -> Definition {
        return Definition(clazz: clazz);
    }

    open class func properties() -> Properties {
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
    open func asJSON(_ source : AnyObject) throws -> String {
        let result = JSONBuilder();

        result.append("{")
        result.increment()

        try toJSON.map(source, direction: .source_2_TARGET, target: result)

        result.decrement();
        result.append("\n}")

        return result.builder.toString()
    }

    /// convert a json string into an object
    /// - Parameter json: the json string
    /// - Returns: the object
    open func fromJSON(_ json : String) throws -> AnyObject {
        let data = json.data(using: String.Encoding.utf8, allowLossyConversion: false)!

        let jsonData = try JSONContainer(data: JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as! [String:AnyObject]);

        return try initialFromMapper!.map(jsonData, direction: .source_2_TARGET)!
    }

    /// convert a json string into an object
    /// - Parameter json: the json string
    /// - Returns: the object
    open func fromJSON<T>(_ type : T.Type, json : String) throws -> T {
        let data = json.data(using: String.Encoding.utf8, allowLossyConversion: false)!

        let jsonData = try JSONContainer(data: JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as! [String:AnyObject]);

        return try initialFromMapper!.map(jsonData, direction: .source_2_TARGET) as! T
    }
}

func ==(lhs: JSON.TypeKey, rhs: JSON.TypeKey) -> Bool {
    return lhs.type == rhs.type
}
