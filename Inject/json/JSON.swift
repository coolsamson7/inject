//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class Types {
    // class funcs

    // TODO: this is just a hack...
    class func unwrapOptionalType(type: Any.Type) -> String {
        var name = "\(type)"

        if name.containsString("<") {
            // e.g Swift.Optional<Foo>

            name = name[name.indexOf("<") + 1 ..< name.lastIndexOf(">")]
        }

        return name;
    }
}

public class JSON {
    // local classes

    class JSONOperation {
        func resolveWrite(definition : MappingDefinition, last : Bool) throws -> Void {
        }

        func resolveRead(mappers : [String:Mapper] , mappingDefinition : MappingDefinition) throws -> Void {
        }
    }

    class JSONBuilder : NSObject {
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
        var deep : Bool

        // init

        init(property : String, deep : Bool = false) {
            self.deep = deep
            self.property = property
        }

        // override

        override func resolveWrite(definition : MappingDefinition, last: Bool) throws -> Void {
            let bean = try BeanDescriptor.forClass(definition.target[0])

            let prop = bean.findProperty(property)

            if prop != nil {
                definition.map([MappingDefinition.BeanPropertyAccessor(propertyName: property)], target: [JSONWriteAccessor(propertyName: property, type: prop!.getPropertyType(), deep: deep, last: last)])
            }
        }

        override func resolveRead(mappers : [String:Mapper], mappingDefinition : MappingDefinition) throws -> Void {
            let bean = try BeanDescriptor.forClass(mappingDefinition.target[1])

            let prop = bean.findProperty(property)

            if prop != nil {
                mappingDefinition.map([JSONReadAccessor(mappers: mappers, propertyName: property, type: prop!.getPropertyType(), deep: deep)], target: [MappingDefinition.BeanPropertyAccessor(propertyName: property)])
            }
        }
    }

    class Definition {
        // instance data

        var clazz : AnyClass
        var operations = [JSONOperation]()

        // init

        init(clazz : AnyClass) {
            self.clazz = clazz
        }

        // fluent

        func map(property: String, deep: Bool = false) -> Definition {
            operations.append(JSONProperty(property: property, deep : deep))

            return self
        }
    }

    class JSONWriteAccessor : Accessor {
        // local classes

        class WriteProperty: Property<MappingContext> {
            // instance data

            var property : String
            var deep : Bool
            var last : Bool

            // init

            init(property: String, deep : Bool, last : Bool) {
                self.property = property
                self.deep = deep
                self.last = last
            }

            // override

            override func set(object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
                if let builder = object as? JSONBuilder {
                    builder.append("\n").indent().append("\"\(property)\": ")

                    if value == nil {
                        builder.append("nil")
                    }
                    else {
                        if (deep) {
                            builder.append("{").increment()

                            try context.mapper.map(value! as! AnyObject, context: context, target: builder)

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

        // instance data

        var propertyName: String;
        var _deep: Bool
        var last : Bool

        // constructor

        init(propertyName: String, type: Any.Type, deep: Bool,  last : Bool) {
            self.propertyName = propertyName;
            self._deep = deep
            self.last = last

            super.init(overrideType: type);
        }

        // implement Accessor

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

        // CustomStringConvertible

        override var description: String {
            return propertyName
        }

    }

    class JSONContainer {
        // instance data

        var data : [String:AnyObject];

        // init

        init(data : [String:AnyObject]) {
            self.data = data
        }
    }

    class JSONReadAccessor : Accessor {
        // local classes

        class ReadProperty: Property<MappingContext> {
            // instance data

            var property : String
            var type : Any.Type?

            // init

            init(type : Any.Type?, property: String) {
                self.type = type
                self.property = property
            }

            // override

            override func get(object: AnyObject!, context: MappingContext) throws -> Any {
                var result : AnyObject?;
                if let data = object as? JSONContainer {
                    result = data.data[property]
                }

                print("read \(result) of type \(result.dynamicType)");

                return result
            }
        }

        class ReadDeepProperty : ReadProperty {
            // instance data

            var mapper : Mapper

            // init

            init(mapper : Mapper, type : Any.Type?, property: String) {
                self.mapper = mapper

                super.init(type : type, property: property);
            }

            // override

            override func get(object: AnyObject!, context: MappingContext) throws -> Any {
                var result = try super.get(object, context: context)

                if let dictionary = result as? [String:AnyObject]  {
                    let container = JSONContainer(data: dictionary)

                    result = try mapper.map(container, direction: .SOURCE_2_TARGET)!
                }

                return result;
            }
        }

        // instance data

        var propertyName: String;
        var _deep: Bool
        var mappers : [String:Mapper]

        // constructor

        init(mappers : [String:Mapper], propertyName: String, type: Any.Type, deep: Bool) {
            self.propertyName = propertyName;
            self._deep = deep
            self.mappers = mappers

            super.init(overrideType: type);
        }

        // implement Accessor

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
                let mapper = mappers[Types.unwrapOptionalType(expectedType!)]; // TODO: FOO
                if (mapper == nil) {
                    fatalError("unknown mapper for type \(expectedType!)");
                }

                return ReadDeepProperty(mapper: mapper!, type: expectedType, property: propertyName);
            }
            else {
                return ReadProperty(type: expectedType, property: propertyName);
            }
        }

        override func isReadOnly() -> Bool {
            return false;
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

        // CustomStringConvertible

        override var description: String {
            return propertyName
        }

    }

    // class functions

    class func mapping(clazz : AnyClass) -> Definition {
        return Definition(clazz: clazz);
    }

    // get rid of Optional, etc. types...
    // what about Array?

    class func className(clazz : Any.Type) -> String {
        var name = "\(clazz)"

        if name.containsString("<") {
            // e.g Swift.Optional<Foo>

            name = name[name.indexOf("<") + 1..<name.lastIndexOf(">")]
        }

        return name;
    }

    // instance data

    var toJSON : Mapper;
    var initialFromMapper : Mapper?;


    // init

    init(mappings: Definition...) throws {
        // write

        var mappingDefinitions = [MappingDefinition]();

        for mapping in mappings {
            let mappingDefinition = MappingDefinition(sourceBean:  mapping.clazz, targetBean: JSONBuilder.self)

            var index = 0
            for operation in mapping.operations {
                try operation.resolveWrite(mappingDefinition, last: index++ == mapping.operations.count - 1)
            }

            mappingDefinitions.append(mappingDefinition)
        }

        toJSON = Mapper(mappings: mappingDefinitions)

        // read

        var mappers = [String:Mapper]()

        // create mappers first so we can pass them to deep mappings

        for mapping in mappings {
            // we need different mappers since the source object is always the same :-(

            let mapper = Mapper(mappings: [MappingDefinition(sourceBean: JSONContainer.self, targetBean: mapping.clazz)])

            if initialFromMapper == nil {
                initialFromMapper = mapper
            }

            mappers[Types.unwrapOptionalType(mapping.clazz)] = mapper
        }

        // initialize definitions

        for mapping in mappings {
            // retrieve mapper

            let mapper = mappers[Types.unwrapOptionalType(mapping.clazz)]!
            let mappingDefinition = mapper.definitions![0]

            // resolve

            for operation in mapping.operations {
                try operation.resolveRead(mappers, mappingDefinition: mappingDefinition)
            }
        }
    }

    func asJSON(source : AnyObject) throws -> String {
        let result = JSONBuilder();

        result.append("{")
        result.increment()

        try toJSON.map(source, direction: .SOURCE_2_TARGET, target: result)

        result.decrement();
        result.append("\n}")

        return result.builder.toString()
    }

    func fromJSON(json : String) throws -> AnyObject {
        let data = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

        let jsonData = try JSONContainer(data: NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String:AnyObject]);

        return try initialFromMapper!.map(jsonData, direction: .SOURCE_2_TARGET)!
    }
}