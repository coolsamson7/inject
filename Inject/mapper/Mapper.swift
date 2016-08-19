//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class MappingOperation: Operation<MappingContext> {
    // Compiler ERROR WTF
    // init

    override init(source: Property<MappingContext>, target: Property<MappingContext>) {
        super.init(source: source, target: target)
    }
}

public enum MapperError: ErrorType, CustomStringConvertible {
    case Definition(message:String, definition : MappingDefinition?, match: MappingDefinition.Match?, accessor: Accessor?)
    case Operation(message:String, mapping: Mapping?, operation : MappingOperation?, source: AnyObject?, target : AnyObject?)

    // CustomStringConvertible

    public var description: String {
        let builder = StringBuilder();

        switch self {
            case .Operation(let message, let mapping, let operation, let source, let target):
                builder.append(message).append(" ");

                if mapping != nil {
                    builder.append("mapping: ").append(mapping!).append(" ")
                }

                if operation != nil {
                    builder.append("operation: ").append(operation!).append(" ")
                }

                if source != nil {
                    builder.append("source: \(source) ")
                }

                if target != nil {
                    builder.append("target: \(target) ")
                }

            case .Definition(let message, let definition, let match, let accessor):
                builder.append(message).append(" ");

                if accessor != nil {
                    builder.append("accessor: ").append(accessor!).append(" ")
                }

                if match != nil {
                    builder.append("match: ").append(match!).append(" ")
                }

                if definition != nil {
                    builder.append("definition: ").append(definition!).append(" ")
                }
        }

        return builder.toString()
    }
}

public class Accessor: CustomStringConvertible {
    // instance data

    var overrideType: Any.Type?;

    // constructor

    init(overrideType: Any.Type?) {
        self.overrideType = overrideType
    }

    // implement Accessor

    public func cast(clazz: AnyClass) -> Accessor {
        overrideType = clazz;

        return self;
    }

    public func isReadOnly() -> Bool {
        return false;
    }

    public func deep() -> Bool {
        return false;
    }

    public func getIndex() -> Int {
        fatalError("is only valid for BeanPropertyAccessor!s");
    }

    public func getOverallIndex() -> Int {
        fatalError("is only valid for BeanPropertyAccessor!s");
    }

    // CustomStringConvertible

    public var description: String {
        return getName()
    }

    // abstract

    public func getName() -> String {
        fatalError("Accessor.getName is abstract");
    }

    public func resolve(clazz: Any.Type) throws -> Void {
        fatalError("Accessor.resolve is abstract");
    }

    public func isAttribute() -> Bool {
        return false;
    }

    public func isArray() -> Bool {
        return false
    }

    public func getType() -> Any.Type {
        fatalError("Accessor.getType is abstract");
    }

    public func makeTransformerProperty(mode: MappingDefinition.Mode, expectedType: Any.Type?, transformerSourceProperty: Property<MappingContext>?) -> Property<MappingContext> {
        fatalError("Accessor.makeTransformerProperty is abstract");
    }

    public func getValue(instance: AnyObject) throws -> Any? {
        fatalError("Accessor.getValue is abstract");
    }

    public func setValue(instance: AnyObject, value: Any?, mappingContext: MappingContext) throws -> Void {
        fatalError("Accessor.setValue is abstract");
    }

    public func equals(object: AnyObject) -> Bool {
        return false
    }
}

public protocol ObjectFactory {
    /**
     * create a new instance of the specified class.
     *
     * @param source the source object
     * @param clazz  the class
     * @return the new instance
     */
    func createBean(source: AnyObject, clazz: AnyClass) -> AnyObject;
}

public protocol CompositeFactory {
    func createComposite(clazz: AnyClass, arguments: AnyObject...) -> AnyObject;
}

public class MappingConversion {
    // instance data

    var sourceConversion : Conversion?
    var targetConversion : Conversion?

    // init

    init(sourceConversion : Conversion?, targetConversion : Conversion?) {
        self.sourceConversion = sourceConversion
        self.targetConversion = targetConversion
    }

    // methods

    /**
     * convert the specified source object in the target format.
     *
     * @param source the source
     * @return the target format
     */
    func convertSource(source: Any?) throws -> Any? {
        return sourceConversion != nil ? try sourceConversion!(object: source) : source
    }

    /**
     * convert the specified target object in the source format.
     *
     * @param target the target
     * @return the source format
     */
    func convertTarget(target: Any?) throws -> Any? {
        return targetConversion != nil ? try targetConversion!(object: target) : target
    }
}

public class MappingFinalizer {
    /**
     * finalize a source object.
     *
     * @param source  the source object
     * @param target  the target
     * @param context the specific context
     */
    func finalizeSource(source: AnyObject, target: AnyObject, context: MappingContext) -> Void {

    }

    /**
     * finalize a target object.
     *
     * @param source  the source
     * @param target  the target object
     * @param context the context
     */
    func finalizeTarget(source: AnyObject, target: AnyObject, context: MappingContext) -> Void {

    }
}

// must be global darn...

public func ==(lhs: MappingDefinition.Match, rhs: MappingDefinition.Match) -> Bool {
    return lhs.equals(rhs);
}


public class MappingDefinition: CustomStringConvertible, CustomDebugStringConvertible {
    // local classes

    static var SOURCE = 0;
    static var TARGET = 1;
    static var SOURCE_2_TARGET = 0;
    static var TARGET_2_SOURCE = 1;

    public enum Mode {
        case READ
        case WRITE
    }

    public class CompositeDefinition {
        // instance data

        var nArgs: Int;
        var outerComposite: Int;
        var outerIndex: Int;

        // constructor

        init(nargs: Int, outerComposite: Int, outerIndex: Int) {
            self.nArgs = nargs;
            self.outerComposite = outerComposite;
            self.outerIndex = outerIndex;
        }

        // public

        public func makeCreator(mapper: Mapper) -> Mapping.CompositeBuffer {
            fatalError("CompositeDefinition.makeCreator NYI");
        }
    }

    public class ImmutableCompositeDefinition: CompositeDefinition {
        // instance data

        private var clazz: AnyClass;
        private var parentAccessor: Accessor?;

        // constructor

        init(clazz: AnyClass, int nargs: Int, outerComposite: Int, outerIndex: Int, parentAccessor: Accessor?) {
            self.clazz = clazz;
            self.parentAccessor = parentAccessor;

            super.init(nargs: nargs, outerComposite: outerComposite, outerIndex: outerIndex);


        }

        // public

        override public func makeCreator(mapper: Mapper) -> Mapping.CompositeBuffer {
            return Mapping.ImmutableCompositeBuffer(mapper: mapper, clazz: clazz, nargs: nArgs, outerComposite: outerComposite, outerIndex: outerIndex, parentAccessor: parentAccessor!);
        }
    }

    public class MutableCompositeDefinition: CompositeDefinition {
        // instance data

        private var clazz: AnyClass;
        private var parentAccessor: Accessor?;

        // constructor

        init(clazz: AnyClass, nargs: Int, outerComposite: Int, outerIndex: Int, parentAccessor: Accessor?) {


            self.clazz = clazz;
            self.parentAccessor = parentAccessor;

            super.init(nargs: nargs, outerComposite: outerComposite, outerIndex: outerIndex);
        }

        // public

        override public func makeCreator(mapper: Mapper) -> Mapping.CompositeBuffer {
            return Mapping.MutableCompositeBuffer(mapper: mapper, clazz: clazz, nargs: nArgs, outerComposite: outerComposite, outerIndex: outerIndex, parentAccessor: parentAccessor!);
        }
    }

    public class BeanPropertyAccessor: Accessor {
        // instance data

        var propertyName: String;
        var property: BeanDescriptor.PropertyDescriptor?;

        // constructor

        init(propertyName: String) {
            self.propertyName = propertyName;

            super.init(overrideType: nil);
        }


        init(propertyName: String, overrideType: AnyClass) {
            self.propertyName = propertyName;

            super.init(overrideType: overrideType)
        }

        init(property: BeanDescriptor.PropertyDescriptor) {
            self.property = property;
            propertyName = property.getName();

            super.init(overrideType: nil);
        }

        // public

        public func getProperty() -> BeanDescriptor.PropertyDescriptor {
            return property!;
        }

        // implement Accessor

        override public func getName() -> String {
            return "\(property?.bean.type).\(property)"
        }

        public override func getIndex() -> Int {
            return property!.getIndex();
        }

        override public func getOverallIndex() -> Int {
            return property!.getOverallIndex();
        }

        override public func resolve(clazz: Any.Type) throws -> Void {
            property = try BeanDescriptor.forClass(clazz as! AnyClass).findProperty(propertyName);

            if (property == nil) {
                throw MapperError.Definition(message: "unknown property \(clazz).\(propertyName)", definition: nil, match: nil, accessor: nil);
            }

            // TODO if (overrideType != nil && !property.getPropertyType().isAssignableFrom(overrideType)) {
            //    throw MapperError.Definition(message: "cannot cast " + property.getPropertyType().getSimpleName() + " to overriding type " + overrideType.getSimpleName());
            //}
        }

        override public func getType() -> Any.Type {
            return overrideType != nil ? overrideType! : property!.getPropertyType()
        }

        override public func isAttribute() -> Bool {
            return property!.isAttribute()
        }

        override public func isArray() -> Bool {
            return property!.isArray()
        }


        override public func makeTransformerProperty(mode: MappingDefinition.Mode, expectedType: Any.Type?, transformerSourceProperty: Property<MappingContext>?) -> Property<MappingContext> {
            return BeanProperty<MappingContext>(property: property!);
        }

        override public func getValue(instance: AnyObject) throws -> Any? {
            return property!.get(instance);
        }

        override public func setValue(instance: AnyObject, value: Any?, mappingContext: MappingContext) throws -> Void {
            try property!.set(instance, value: value);
        }

        override public func isReadOnly() -> Bool {
            return false; // TODO property.isReadOnly();
        }

        override public func deep() -> Bool {
            return !property!.isAttribute();
        }

        override public func equals(object: AnyObject) -> Bool {
            if let accessor = object as? BeanPropertyAccessor {
                return propertyName == accessor.propertyName
            }
            else {
                return false;
            }

        }

        // CustomStringConvertible

        override public var description: String {
            return propertyName
        }
    }

    public class PropertyQualifier: CustomStringConvertible {
        // instance data

        var except: [String];
        var local: Bool = false;

        // constructor

        init(local : Bool, except: [String]) {
            self.local = local
            self.except = except;
        }

        // public

        public func except(except: [String]) -> PropertyQualifier {
            self.except = except;

            return self;
        }

        // abstract

        public func computeProperties(sourceBean: AnyClass, targetBean: AnyClass) -> [String] {
            return []; // darn, abstract
        }

        public func traceMapping(builder : StringBuilder) -> Void {
            if (except.count > 0) {
                builder.append(" except {");
                for i in 0..<except.count {
                    if (i > 0) {
                        builder.append(", ");
                    }

                    builder.append(except[i]);
                } // for

                builder.append("}");
            } // if
        }

        // CustomStringConvertible

        public var description: String {
            let builder = StringBuilder(string: "properties")

            traceMapping(builder);

            return builder.toString();
        }
    }

    public class Properties: PropertyQualifier {
        // instance data

        var properties: [String];

        // constructor

        init(properties: [String]) {
            self.properties = properties;

            super.init(local: false, except: []);
        }

        // implement PropertyQualifier

        override public func computeProperties(sourceClass: AnyClass, targetBean targetClass: AnyClass) -> [String] {
            let sourceBean = try! BeanDescriptor.forClass(sourceClass);
            let targetBean = try! BeanDescriptor.forClass(targetClass);

            var result = [String]()

            for property in properties {
                if except.contains(property) {
                    continue
                }

                if (sourceBean.findProperty(property) != nil && targetBean.findProperty(property) != nil) {
                    result.append(property);
                }
            }

            return result;
        }

        override public func traceMapping(builder : StringBuilder) -> Void {
            for i in 0..<properties.count {
                if (i > 0) {
                    builder.append(", ");
                }

                builder.append(properties[i]);
            } // for

            super.traceMapping(builder);
        }
    }

    public class AllProperties : PropertyQualifier {
        // constructor

        override init(local : Bool, except: [String]) {
            super.init(local: local, except: except);
        }

        // implement PropertyQualifier

        override public func computeProperties(sourceBean : AnyClass, targetBean : AnyClass) -> [String] {
            let sourceBean = try! BeanDescriptor.forClass(sourceBean);
            let targetBean = try! BeanDescriptor.forClass(targetBean);

            var properties : [String] = []

            for property in sourceBean.getProperties() {
                if except.contains(property.name) {
                    continue
                }

                if (targetBean.findProperty(property.getName()) != nil) {
                    properties.append(property.getName());
                }
            }

            return properties;
        }

        override public func traceMapping(builder : StringBuilder) -> Void {
            builder.append("properties");

            super.traceMapping(builder);
        }
    }

    public class MapOperation: CustomStringConvertible {
        // instance data

        var conversion: MappingConversion?;

        // constructor

        init(conversion: MappingConversion?) {
            self.conversion = conversion
        }

        // public

        public func getConversion() -> MappingConversion? {
            return conversion;
        }

        // CustomStringConvertible

        public var description: String {
            return "\(self.dynamicType)"
        }

        // abstract

        public func traceMapping(builder : StringBuilder) -> Void {
        }

        func findMatches(definition: MappingDefinition, matches: Matches) -> Void {
            fatalError("MapOperation.findMatches is abstract")
        }

        public func deep() -> Bool {
            fatalError("implement")
        }
    }

    public class MapAccessor: MapOperation {
        // instance data

        private var source: [Accessor];
        private var target: [Accessor];
        private var _deep: Bool;

        // constructor

        init(source: [Accessor], target: [Accessor], conversion: MappingConversion?, deep: Bool) {
            self.source = source;
            self.target = target;
            self._deep = deep;

            super.init(conversion: conversion)
        }

        // implement MapOperation

        override public func findMatches(definition: MappingDefinition, matches: Matches) -> Void {
            matches.addMatch(Match(source: source, target: target, mapOperation: self));
        }

        override public func traceMapping(builder : StringBuilder) -> Void {
            builder.append("   ");
            for i in 0..<source.count {
                if (i > 0) {
                    builder.append(".");}

                builder.append(source[i]);
            } // if

            builder.append(" -> ");
            for i in 0..<target.count {
                if (i > 0) {
                    builder.append(".");
                }
                builder.append(target[i]);
            } // if

            builder.append("\n");
        }

        override public func deep() -> Bool {
            return _deep;
        }

        // override

        override public var description: String {
            let builder = StringBuilder(string: "map ");

            // source

            for accessor in source {
                builder.append(accessor).append(" ");
            }


            builder.append(" - ");

            // target

            for accessor in target {
                builder.append(accessor).append(" ");
            }

            if (_deep) {
                builder.append(" deep");
            }

            if (conversion != nil) {
                builder.append(" conversion \(conversion)");
            }

            // done

            return builder.toString();
        }
    }

    public class MapProperties: MapOperation {
        // instance data

        var propertyQualifier: PropertyQualifier;

        // constructor

        init(propertyQualifier: PropertyQualifier) {
            self.propertyQualifier = propertyQualifier;

            super.init(conversion: nil)
        }

        // implement MapOperation

        override func findMatches(definition: MappingDefinition, matches: Matches) -> Void {
            for property in propertyQualifier.computeProperties(definition.target[SOURCE], targetBean: definition.target[TARGET]) {
                matches.addMatch(Match(source: [property], target: [property], mapOperation: self))
            }
        }

        override public func traceMapping(builder : StringBuilder) -> Void {
            builder.append("   ");

            propertyQualifier.traceMapping(builder);

            builder.append("\n");
        }

        override public func deep() -> Bool {
            return false;
        }

        // override

        override public var description: String {
            let builder = StringBuilder();

            builder.append("map ").append(propertyQualifier);

            if (conversion != nil) {
                builder.append(" conversion \(conversion)");
            }

            return builder.toString();
        }
    }

    public class Match: Hashable, CustomStringConvertible {
        // class methods

        class func makePath(path: [String]) -> [Accessor] {
            var accessor = [Accessor]();

            for element in path {
                let propertyAccessor = BeanPropertyAccessor(propertyName: element);

                accessor.append(propertyAccessor)
            } // for

            return accessor;
        }

        // instance data

        var hash: Int
        var mapOperation: MapOperation;
        var paths: [[Accessor]]; // SOURCE and TARGET paths...

        // constructor

        init(source: [String], target: [String], mapOperation: MapOperation) {
            self.paths = [
                    Match.makePath(source), // allow functions
                    Match.makePath(target)
            ]
            self.hash = Match.computeHash(source, target: target)
            self.mapOperation = mapOperation;
        }

        init(source: [Accessor], target: [Accessor], mapOperation: MapOperation) {
            self.paths = [source, target];
            self.hash = Match.computeHash(source, target: target)
            self.mapOperation = mapOperation;
        }

        init(source: Accessor, target: Accessor, mapOperation: MapOperation) {
            self.paths = [
                    [source],
                    [target]
            ]

            self.mapOperation = mapOperation;
            self.hash = Match.computeHash(paths[0], target: paths[1])
        }

        // public

        func deep() -> Bool {
            return mapOperation.deep();
        }

        func getConversion() -> MappingConversion? {
            return mapOperation.getConversion();
        }

        // private

        private class func computeHash(source: [String], target: [String]) -> Int {
            var hash = 0;

            for leg in source {
                hash = 31 &* hash &+ leg.hash
            }

            for leg in target {
                hash = 31 &* hash &+ leg.hash
            }

            return hash
        }

        private class func computeHash(source: [Accessor], target: [Accessor]) -> Int {
            var hash = 0;

            for leg in source {
                hash = 31 &* hash &+ leg.getName().hash
            }

            for leg in target {
                hash = 31 &* hash &+ leg.getName().hash
            }

            return hash
        }

        // Hashable

        public var hashValue: Int {
            get {
                return hash
            }
        }

        // called by ==

        public func equals(object: AnyObject) -> Bool {
            if let match = object as? Match {
                if match === self {
                    return true;
                }

                // the hard way

                if (paths[0].count != match.paths[0].count) {
                    return false
                }

                if (paths[1].count != match.paths[1].count) {
                    return false
                }

                for side in 0 ..< 2 {
                    for i in 0 ..< paths[side].count {
                        if (!paths[side][i].equals(match.paths[side][i])) {
                            return false
                        }
                    }
                }

                return true
            } // if

            return false;
        }

        // CustomStringConvertible

        public var description: String {
            let builder = StringBuilder();

            builder.append("operation: ").append(mapOperation);

            /* source

            if (paths[SOURCE] != null)
            for (Accessor accessor : paths[0])
               builder.append(accessor).append(" ");

            builder.append(" - ");

            // target

            if (paths[TARGET] != null)
            for (Accessor accessor : paths[SOURCE])
               builder.append(accessor).append(" ");
        */
            return builder.toString();
        }
    }

    // ConvertSource

    public class ConvertSource : Property<MappingContext> {
        // instance data

        private var  property : Property<MappingContext>
        private var  conversion : MappingConversion
        private var sourceAllowNull = true

        // constructor

        init(property : Property<MappingContext>, conversion: MappingConversion) {
            self.property = property
            self.conversion = conversion

        }

        // implement Property

        public override func get(object : AnyObject!, context : MappingContext ) throws -> Any? {
            let value = try property.get(object, context: context);

            // if (value == nil) {
            //     return sourceAllowNull ? conversion.convertTarget(value) : nil;
            //}
            //else {
            return try conversion.convertTarget(value)
            //}
        }


        override public func set(object : AnyObject!, value : Any?, context : MappingContext ) throws -> Void {
            //if (value == nil) {
            //    value = sourceAllowNull ? conversion.convertSource(nil) : nil;
            //}
            //else {
            //   value = conversion.convertSource(value);
            //}

            try property.set(object, value: conversion.convertSource(value), context: context)
        }

        // CustomStringConvertible

        override public var description: String {
            //if (conversion instanceof ConversionFactory.DefaultConversion) {
            //    return "cast(" + ((ConversionFactory.DefaultConversion) conversion).getTargetClass().getSimpleName() + ") " + property.toString();
            //}
//else {
            return "convert(\(conversion)) \(property) "
//}
        }
    }

    // ConvertTarget

    public class ConvertTarget : Property<MappingContext> {
        // instance data

        private var property : Property<MappingContext>
        private var conversion : MappingConversion
        private var sourceAllowNull = true

        // constructor

        init(property : Property<MappingContext>, conversion: MappingConversion) {
            self.property = property;
            self.conversion = conversion;

        }

        // implement Property

        override public func get(object : AnyObject!, context : MappingContext) throws -> Any? {
            let value = try property.get(object, context: context);

            // if (value == nil) {
            //     return sourceAllowNull ? conversion.convertTarget(value) : nil;
            //}
            //else {
            return try conversion.convertSource(value);
            //}
        }


        override public func set(object : AnyObject!, value : Any?, context : MappingContext ) throws -> Void {
            //if (value == nil) {
            //    value = sourceAllowNull ? conversion.convertSource(nil) : nil;
            //}
            //else {
            //   value = conversion.convertSource(value);
            //}

            try property.set(object, value: conversion.convertTarget(value), context: context)
        }

        // CustomStringConvertible

        override public var description: String {
            //if (conversion instanceof ConversionFactory.DefaultConversion) {
            //    return "cast(" + ((ConversionFactory.DefaultConversion) conversion).getTargetClass().getSimpleName() + ") " + property.toString();
            //}
//else {
            return "convert(\(conversion)) \(property) "
//}
        }
    }

    //

    public class Matches /*: CustomStringConvertible*/ {
        // local classes

        public class PathNode {
            // instance data

            var accessor: Accessor
            var match: Match? // only leaf nodes will reference the original match ( a path )
            var parent: PathNode?
            var children = [PathNode]()

            // constructor

            init(parent: PathNode?, step: Accessor, match: Match?) {
                self.parent = parent;
                self.accessor = step
                self.match = match
            }

            // protected

            func deep() -> Bool {
                return match!.deep();
            }

            func getParent() -> PathNode? {
                return parent;
            }

            func getChildren() -> [PathNode] {
                return children;
            }

            func isRoot() -> Bool {
                return parent == nil;
            }

            func isLeaf() -> Bool {
                return children.count == 0;
            }

            func isInnerNode() -> Bool {
                return children.count > 0;
            }

            func isAttribute() -> Bool {
                return accessor.isAttribute();
            }

            func getIndex() -> Int {
                return parent != nil ? parent!.getChildren().indexOf({ $0 === self })! : 0;
            }

            // public

            public func rootNode() -> PathNode {
                return parent != nil ? parent!.rootNode() : self;
            }

            public func insertMatch(tree: PathTree, match: Match, index: Int, side: Int) throws -> Void {
                var root: PathNode? = nil;
                for node in children {
                    if node.accessor.equals(match.paths[side][index] as AnyObject) {
                        // TODO
                        root = node;
                        break;
                    } // if
                }

                if (root == nil) {
                    root = try tree.makeNode(
                            self, // parent
                            step: match.paths[side][index], // step
                            match: (match.paths[side].count - 1 == index ? match : nil)
                            )
                    children.append(root!);
                }

                if (match.paths[side].count > index + 1) {
                    try root!.insertMatch(tree, match: match, index: index + 1, side: side);
                }
            }

            // pre: this node matches index - 1

            public func findMatchingNode(match: Match, index: Int, side: Int) -> PathNode {
                if (index < match.paths[side].count) {
                    for child in children {
                        if (child.accessor.equals(match.paths[side][index])) {
                            return child.findMatchingNode(match, index: index + 1, side: side);
                        }
                    }
                } // if

                return self;
            }
        }

        public class PathTree {
            // instance data

            var roots = [PathNode]();
            var side: Int;

            // constructor

            init(side: Int) {
                self.side = side;
            }

            // public

            public func getSide() -> Int {
                return side;
            }

            public func getRoots() -> [PathNode] {
                return roots;
            }

            // protected

            func makeNode(parent: PathNode?, step: Accessor, match: Match?) throws -> PathNode {
                return PathNode(
                        parent: parent, // parent
                        step: step, // step
                        match: match
                        );
            }

            // protected

            func insertMatch(match: Match) throws -> Void {
                var root: PathNode? = nil;
                for node in roots {
                    if (node.match == match || (node.accessor.equals(match.paths[side][0]))) {
                        root = node;
                        break;
                    } // if
                }

                if (root == nil) {
                    let step: Accessor = match.paths[side][0]
                    let match: Match? = match.paths[side].count == 1 ? match : nil
                    root = try makeNode(
                            root, // parent
                            step: step, // step
                            match: match
                            )

                    roots.append(root!);
                }

                if (match.paths[side].count > 1) {
                    try root!.insertMatch(self, match: match, index: 1, side: side);
                }
            }

            func findNode(match: Match) -> PathNode {
                for node in roots {
                    if (node.match == match) {
                        return node;
                    }

                    else if (node.accessor.equals(match.paths[side][0])) {
                        return node.findMatchingNode(match, index: 1, side: side);
                    }
                } // for

                fatalError("should not happen")
                //return nil; // make the compiler happy
            }
        }

        class SourceNode: PathNode {
            // instance data

            var index = -1; // this will hold the index in the stack of intermediate results in the context
            var type: Any.Type?;
            var fetchProperty: Property<MappingContext>?; // the transformer property needed to fetch the value

            // constructor

            init(parent: SourceNode?, step: Accessor, match: Match?) {
                super.init(parent: parent, step: step, match: match);

                type = accessor.getType() //TODO accessor != nil ? accessor!.getType() : nil;
            }

            // override

            override func isAttribute() -> Bool {
                return /* TODO accessor == nil ||*/ accessor.isAttribute();
            }

            func getSourceParent() -> SourceNode? {
                return getParent() as? SourceNode
            }

            // private

            func fetchValue(sourceTree: SourceTree, expectedType: Any.Type, inout operations: [Operation<MappingContext>]) -> Void {
                // recursion

                if (!isRoot()) {
                    getSourceParent()!.fetchValue(sourceTree, expectedType: expectedType, operations: &operations);
                }

                // fetch a stored value

                if (fetchProperty == nil) {
                    // root, no children...

                    if (isRoot()) {
                        fetchProperty = accessor.makeTransformerProperty(Mode.READ, expectedType: expectedType, transformerSourceProperty: nil);

                        type = accessor.getType();
                    }

                    else {
                        // inner node or leaf

                        fetchProperty = PeekValueProperty(int: getSourceParent()!.index, property: accessor.makeTransformerProperty(Mode.READ, expectedType: expectedType, transformerSourceProperty: nil));
                        type = accessor.getType();

                    }

                    // in case of inner nodes take the result and remember it

                    if (!isLeaf()) {
                        // store the intermediate result

                        index = sourceTree.stackSize; // that's my index

                        sourceTree.stackSize += 1

                        operations.append(MappingOperation(source: fetchProperty!, target: PushValueProperty(index: index)));
                    }
                }
            }
        }

        class SourceTree: PathTree {
            // instance data

            var stackSize = 0;
            var type: Any.Type;

            // constructor

            init(type: AnyClass, matches: [Match], sourceIndex: Int) throws {


                self.type = type;

                super.init(side: sourceIndex);

                for match in matches {
                    try insertMatch(match);
                }
            }

            // override

            override func makeNode(parent: PathNode?, step: Accessor, match: Match?) throws -> PathNode {
                // constant value instead of a path

                try step.resolve(parent == nil ? type : parent!.accessor.getType());

                return SourceNode(
                        parent: parent as? SourceNode, // parent
                        step: step, // step
                        match: match
                        );
            }
        }

        // local classes

        class TargetNode: PathNode {
            // instance data

            var compositeIndex = -1;
            var immutable = false;

            // constructor

            init(parent: TargetNode?, step: Accessor, match: Match?) {
                super.init(parent: parent, step: step, match: match);
            }

            // protected

            func childIndex(child: TargetNode) -> Int {
                if immutable {
                    return child.accessor.getOverallIndex();
                }
                else {
                    return getChildren().indexOf({ $0 === child })!;
                }
            }

            func getTargetParent() -> TargetNode? {
                return getParent() as? TargetNode
            }

            // public

            func makeOperations(direction: Int, sourceTree: SourceTree, mapper: Mapper, definition: MappingDefinition, inout operations: [Operation<MappingContext>]) throws -> Void {
                // check if i am a composite

                let type: Any.Type = accessor.getType();

                if (match == nil) {
                    // this is a composite! register the appropriate definition.

                    // check if this is an immutable composite

                    for child in getChildren() {
                        if (child.accessor.isReadOnly()) {
                            immutable = true; // if one child is read only we need the full  constructor
                            break;
                        } // if
                    }

                    // done

                    if (immutable) {
                        // check if all arguments are mapped

                        if try (getChildren().count <  BeanDescriptor.forClass(type as! AnyClass).getProperties().count) {
                            throw MapperError.Definition(message: "not all properties of the composite \(type) are mapped", definition: definition, match: match, accessor: accessor);
                        }

                        // done

                        compositeIndex = definition.addImmutableCompositeDefinition(int: direction, clazz: type  as! AnyClass, outerComposite: getParent() != nil ? getTargetParent()!.compositeIndex : -1,
                                // index of the parent composite
                                outerIndex: getTargetParent() != nil ? getTargetParent()!.childIndex(self) : -1, // index of this instance in the outer composite (e.g. constructor arg index)
                                parentAccessor: getTargetParent() != nil ? getTargetParent()!.accessor : nil
                                );
                    }
                    else {
                        compositeIndex = definition.addMutableCompositeDefinition(direction, clazz: type as! AnyClass, nargs: getChildren().count, // nargs
                                outerComposite: getTargetParent() != nil ? getTargetParent()!.compositeIndex : -1, // index of the parent composite
                                outerIndex: getTargetParent() != nil ? getTargetParent()!.childIndex(self) : -1,
                                parentAccessor: getTargetParent() != nil ? getTargetParent()!.accessor : nil
                                );
                    }
                } // if

                // recursion

                for child in getChildren() {
                    try (child as! TargetNode).makeOperations(direction, sourceTree: sourceTree, mapper: mapper, definition: definition, operations: &operations);
                }
                // create operation for leaf nodes

                if (match != nil) {
                    let sourceNode: SourceNode = sourceTree.findNode(match!) as! SourceNode;

                    sourceNode.fetchValue(sourceTree, expectedType: type, operations: &operations); // compute property needed to fetch source value

                    try operations.append(makeOperation(mapper, sourceNode: sourceNode, side: 1 - sourceTree.side));
                } // if
            }

            private func maybeConvert(property: Property<MappingContext>, conversion: MappingConversion?, direction: Int) -> Property<MappingContext> {
                if (conversion == nil) {
                    return property;
                }
                else {
                    if (direction == TARGET) {
                        return ConvertSource(property: property, conversion: conversion!);
                    }
                    else {
                        return ConvertTarget(property: property, conversion: conversion!);
                    }
                }
            }

            func mapDeep(mapper: Mapper, source: Accessor, target: Accessor, targetProperty: Property<MappingContext>, conversion: MappingConversion?, int side: Int) throws -> Property<MappingContext> {
                let sourceType: Any.Type = source.getType()
                let targetType: Any.Type = target.getType()
                let isSourceMultiValued = source.isArray()
                let isTargetMultiValued = target.isArray()

                if (isSourceMultiValued != isTargetMultiValued) {
                    throw MapperError.Definition(message: "relations must have the same cardinality", definition: nil, match: match, accessor: target);
                }

                //TODO if (target is RelationshipAccessor) {
                //    return targetProperty; // ugly
                //}

                // check if there are specific mappings

                let origin: BeanDescriptor.PropertyDescriptor? = mapper.specificMapping(source, side: side);

                if (isSourceMultiValued) {
                    if conversion != nil {
                        return MapCollection2Collection(sourceType: sourceType, targetType: targetType, accessor: target, origin: origin);//TODO MapAndConvertCollection2Collection(sourceType, targetType, target, conversion, origin);
                    }
                    else {
                        return MapCollection2Collection(sourceType: sourceType, targetType: targetType, accessor: target, origin: origin);
                    }
                }
                else {
                    return MapDeep(property: target, origin: origin)
                }
            }

            private func needsConversion(fromType: Any.Type, toType: Any.Type) -> Bool {
                return fromType != toType
            }

            private func accessorName(accessor: Accessor) -> String {
                return accessor.getName();
            }

            // side is the target index: either SOURCE or TARGET

            private func makeOperation(mapper: Mapper, sourceNode: SourceNode, side: Int) throws -> Operation<MappingContext> {
                let transformerSourceProperty = sourceNode.fetchProperty; // whatever property

                // is needed to fetch the value, see fetchValue!

                let deep = match!.deep() || sourceNode.accessor.deep(); // relations are considered deep by default!

                var conversion = match!.getConversion();

                /* TODO check manual conversions

                if (conversion != null) {
                    // compare generic types with expected types

                    var conversionClass = conversion.getClass();

                    for (Type interfaceType: conversionClass.getGenericInterfaces())
                    if (interfaceType instanceof ParameterizedType && getRawType(interfaceType) == MappingConversion.class ) {
                    Type[] types = ((ParameterizedType) interfaceType).getActualTypeArguments(); // [from,to]

                    if (side == TARGET) {
                        // direction = SOURCE_2_TARGET
                        //self.accessor=to
                        //source.acessor=from

                        if (!(getRawType(types[SOURCE])).isAssignableFrom(wrapperType(sourceNode.accessor.getType())))
                        throw new MapperException(conversionClass.getSimpleName() + " should convert " + wrapperType(
                                sourceNode.accessor.getType()).getSimpleName() + "'s rather than " + (getRawType(types[SOURCE])).getSimpleName() + "'s");

                        if (!wrapperType(accessor.getType()).isAssignableFrom((getRawType(types[TARGET]))))
                        throw new MapperException(conversionClass.getSimpleName() + " should convert to " + wrapperType(
                                accessor.getType()).getSimpleName() + "'s rather than " + (getRawType(types[TARGET])).getSimpleName() + "'s");
                    } // if
                    else {
                        // side = SOURCE, direction = TARGET_2_SOURCE
                        //self.accessor=from
                        //source.acessor=to
                        if (!(getRawType(types[TARGET])).isAssignableFrom(wrapperType(sourceNode.accessor.getType())))
                        throw new MapperException(conversionClass.getSimpleName() + " should convert " + wrapperType(
                                sourceNode.accessor.getType()).getSimpleName() + "'s rather than " + (getRawType(types[TARGET])).getSimpleName() + "'s");

                        if (!wrapperType(accessor.getType()).isAssignableFrom((getRawType(types[SOURCE]))))
                        throw new MapperException(conversionClass.getSimpleName() + " should convert to " + wrapperType(
                                accessor.getType()).getSimpleName() + "'s rather than " + (getRawType(types[SOURCE])).getSimpleName() + "'s");
                    } // else
                } // if
            } // if */

                // we only need conversion in case of shallow copies!

                if (conversion == nil && !deep) {
                    if (sourceNode.type == nil) {
                        throw MapperError.Definition(message: "unknown source type \(sourceNode.accessor)", definition: nil, match: match, accessor: accessor); // rethrow
                    }

                    if (needsConversion(sourceNode.type!, toType: accessor.getType())) {
                        //print("convert \(sourceNode.type!) to \(accessor.getType())");

                        var conversionFunction : Conversion? = nil
                        if (side == TARGET) {
                            conversionFunction = try mapper.getConversion(sourceNode.type!, targetType: accessor.getType());
                        }
                        else {
                            conversionFunction = try mapper.getConversion(accessor.getType(), targetType: sourceNode.type!);
                        }

                        if (conversionFunction != nil) {
                            conversion = MappingConversion(sourceConversion: side == TARGET ? conversionFunction : nil, targetConversion: side == SOURCE ? conversionFunction : nil)
                        }
                        else {
                            throw MapperError.Definition(message: "unknown conversion from \(sourceNode.type) to \(accessor.getType())", definition: nil, match: match, accessor: accessor)
                        }
                    }
                } // if

                if (!isRoot()) {
                    if (rootNode().accessor.isReadOnly()) {
                        throw  MapperError.Definition(message: "accessorName(rootNode()!.accessor)" + " is read only!", definition: nil, match: match, accessor: accessor); // TODO
                    }
                    // fill a composite

                    if (getTargetParent()!.immutable) {
                        return MappingOperation(source: transformerSourceProperty!, target: maybeConvert(SetCompositeArgument(accessor: accessor, rootAccessor: getTargetParent()!.accessor,
                                compositeIndex: (getParent() as! TargetNode).compositeIndex, // composite index of the parent
                                argumentIndex: accessor.getOverallIndex() // index of the composite property (e.g. needed as the constructor argument )
                                ), conversion: conversion, direction: side));
                    }
                    else {
                        return MappingOperation(source: transformerSourceProperty!, target: maybeConvert(SetCompositeArgument(accessor: accessor, rootAccessor: getTargetParent()!.accessor,
                                compositeIndex: getTargetParent()!.compositeIndex, // composite index of the parent
                                argumentIndex: getIndex() // index of the composite property
                                ), conversion: conversion, direction: side));
                    } // else
                }
                else {
                    // leaf node

                    if (accessor.isReadOnly()) {
                        throw MapperError.Definition(message: "accessorName(rootNode()!.accessor)" + " is read only!", definition: nil, match: match, accessor: accessor); // TODO
                    }

                    let writeProperty = accessor.makeTransformerProperty(Mode.WRITE, expectedType: nil, transformerSourceProperty: transformerSourceProperty);
                    if (deep && match!.getConversion() == nil) {
                        return try MappingOperation(source: transformerSourceProperty!, target: mapDeep(mapper, source: sourceNode.accessor, target: accessor, targetProperty: writeProperty, conversion: conversion, int: side));
                    }
                    else {
                        return MappingOperation(source: transformerSourceProperty!, target: maybeConvert(writeProperty, conversion: conversion, direction: side));
                    }
                }
            } // else
        }

        private class TargetTree: PathTree {
            // instance data

            var bean: AnyClass;

            // constructor

            init(bean: AnyClass, matches: [Match], sourceTree: SourceTree) throws {
                self.bean = bean;

                super.init(side: 1 - sourceTree.getSide());


                // insert matches

                for m in matches {
                    do {
                        try insertMatch(m);
                    }
                    catch MapperError.Definition(let message, let definition, _/*match*/, let accessor) {
                        throw MapperError.Definition(message: message, definition: definition, match: m, accessor: accessor)
                    }
                }
            }

            // public

            func makeOperations(direction: Int, sourceTree: SourceTree, mapper: Mapper, definition: MappingDefinition) throws -> [Operation<MappingContext>] {
                var operations = [Operation<MappingContext>]();

                for node in getRoots() {
                    do {
                        try (node as! TargetNode).makeOperations(direction, sourceTree: sourceTree, mapper: mapper, definition: definition, operations: &operations);
                    }
                    catch MapperError.Definition(let message, let definition, _/*match*/, let accessor) {
                        throw MapperError.Definition(message: message, definition: definition, match: node.match, accessor: accessor)
                    }
                }

                return operations;
            }

            // override

            override func makeNode(parent: PathNode?, step: Accessor, match: Match?) throws -> PathNode {
                do {
                    try step.resolve(parent == nil ? bean : parent!.accessor.getType());

                    return TargetNode(
                            parent: (parent as? TargetNode), // parent
                            step: step, // step
                            match: match
                            );
                }
                catch MapperError.Definition(let message, let definition, _, _/*accessor*/) {
                    throw MapperError.Definition(message: message, definition: definition, match: match, accessor: step)
                }
            }
        }

        // instance data

        var matchSet = Set<Match>();
        var matches = [Match]();

        // public

        public func addMatch(match: Match) -> Void {
            if (!matchSet.contains(match)) {
                matches.append(match);

                matchSet.insert(match);
            } // if
        }

        public func exclude(exclude: Accessor) -> Void {
            /*TODO func from set

            for (Iterator<Match> matches = matchSet.iterator(); matches.hasNext(); ) {
                Match match = matches.next();

                if (match.paths[SOURCE][0].equals(exclude))
                matches.remove();
            }

            // remove from list

            for (Iterator<Match> matches = self.matches.iterator(); matches.hasNext(); ) {
                Match match = matches.next();

                if (match.paths[SOURCE][0].equals(exclude))
                matches.remove();
            } */
        }

        public func makeOperations(mapper: Mapper, definition: MappingDefinition, direction: Int) throws -> (operations:[Operation<MappingContext>], stackSize:Int) {
            let sourceTree = try SourceTree(type: definition.target[direction], matches: matches, sourceIndex: direction);

            return try (
                    TargetTree(bean: definition.target[1 - direction], matches: matches, sourceTree: sourceTree).makeOperations(direction, sourceTree: sourceTree, mapper: mapper, definition: definition),
                    sourceTree.stackSize
                    );
        }
    }

    // instance data

    var target: [AnyClass];
    var conversion: MappingConversion?;
    var finalizer: MappingFinalizer?;
    var operations = [MapOperation]();
    var composites: [[CompositeDefinition]] = [[], []];
    var baseMapping: MappingDefinition?;
    var objectFactories: [ObjectFactory?] = [nil, nil];
    var via: [BeanDescriptor.PropertyDescriptor] = [];
    var cache = true;

    // constructor

    init(sourceBean: AnyClass, targetBean: AnyClass, conversion: MappingConversion? = nil) {
        target = [sourceBean, targetBean];
        self.conversion = conversion;
    }

    // private

    private func addImmutableCompositeDefinition(int side: Int, clazz: AnyClass, outerComposite: Int, outerIndex: Int, parentAccessor: Accessor?) -> Int {
        composites[side].append(ImmutableCompositeDefinition(clazz: clazz, int: try! BeanDescriptor.forClass(clazz).getProperties().count, outerComposite: outerComposite, outerIndex: outerIndex, parentAccessor: parentAccessor));

        return composites[side].count - 1;
    }

    private func addMutableCompositeDefinition(side: Int, clazz: AnyClass, nargs: Int, outerComposite: Int, outerIndex: Int, parentAccessor: Accessor?) -> Int {
        composites[side].append(MutableCompositeDefinition(clazz: clazz, nargs: nargs, outerComposite: outerComposite, outerIndex: outerIndex, parentAccessor: parentAccessor));

        return composites[side].count - 1;
    }


    public func getObjectFactories() -> [ObjectFactory?] {
        return objectFactories;
    }

    // fluent interface

    public func createSource(objectFactory: ObjectFactory) -> MappingDefinition {
        objectFactories[MappingDefinition.SOURCE] = objectFactory;

        return self;
    }

    public func createTarget(objectFactory: ObjectFactory) -> MappingDefinition {
        objectFactories[MappingDefinition.TARGET] = objectFactory;

        return self;
    }

    public func via(clazz : AnyClass, propertyName : String ) throws -> MappingDefinition{
        let propertyDescriptor = try BeanDescriptor.forClass(clazz).findProperty(propertyName); // may return null
        if (propertyDescriptor == nil) {
            throw  MapperError.Definition(message: "unknown property \(clazz).\(propertyName)", definition: self, match: nil, accessor: nil);
        }

        self.via.append(propertyDescriptor!);

        return self;
    }

/**
 * execute the specified {@link MappingFinalizer} for this mapping.
 *
 * @param finalizer a  {@link MappingFinalizer}
 * @return self
 */
    public func finalize(finalizer: MappingFinalizer) -> MappingDefinition {
        /* TODO check types

        Class finalizerClass = finalizer.getClass();
        for (Type interfaceType : finalizerClass.getGenericInterfaces())
        if (interfaceType instanceof ParameterizedType) {
            Type[] types = ((ParameterizedType) interfaceType).getActualTypeArguments(); // [from,to]

            if (!(getRawType(types[0]).isAssignableFrom(self.target[0])))
            throw new MapperDefinitionException(
                    "finalizer " + finalizer.getClass().getSimpleName() + " declares source parameter type " + types[0] + " does not match " + target[0].getSimpleName());

            if (!(getRawType(types[1]).isAssignableFrom(self.target[1])))
            throw new MapperDefinitionException(
                    "finalizer " + finalizer.getClass().getSimpleName() + " declares target parameter type " + types[1] + " does not match " + target[1].getSimpleName());
        } // if */

        // done

        self.finalizer = finalizer;

        return self;
    }

    public func derives(mappingDefinition: MappingDefinition) throws -> MappingDefinition {
        // sanity checks

        if (baseMapping != nil) {
            throw MapperError.Definition(message: "basemapping has been already defined", definition: self, match: nil, accessor: nil);
        }

        // check types

        for _ in 0 ..< target.count {
            //TODO if (!mappingDefinition.target[i].isAssignableFrom(target[i])) {
            //    throw MapperError.Definition(message: "basemapping maps different classes");
            //}
        }

        // done

        baseMapping = mappingDefinition;

        return self;
    }

    public func include(explicitProperties: String...) -> MappingDefinition {
        operations.append(MapProperties(propertyQualifier: Properties(properties: explicitProperties)));

        return self;
    }

    /*public func exclude(exclude: String...) -> MappingDefinition {
        operations.add(ExludeProperties(toAccessors(exclude)));

        return self;
    }

    public func exclude(exclude: Accessor...) -> MappingDefinition {
        operations.add(ExludeProperties(exclude));

        return self;
    }*/

    public func map(propertyQualifier: PropertyQualifier) -> MappingDefinition {
        operations.append(MapProperties(propertyQualifier: propertyQualifier));

        return self;
    }

    public func map(source: [Accessor], target: [Accessor], conversion: MappingConversion? = nil) -> MappingDefinition {
        operations.append(MappingDefinition.MapAccessor(source: source, target: target, conversion: conversion, deep: false));

        return self;
    }

    public func mapDeep(source: [Accessor], target: [Accessor], conversion: MappingConversion? = nil) -> MappingDefinition {
        operations.append(MappingDefinition.MapAccessor(source: source, target: target, conversion: conversion, deep: true));

        return self;
    }

// / map(..) in all kind of combinations

    //public func map(source: Accessor, target: Accessor...) -> MappingDefinition {
    //    return map([source], target, nil);
    //TODO}

    //public func map(source: Accessor, target: Accessor, conversion: MappingConversion) -> MappingDefinition {
    //    return map([source], target: [target], conversion: conversion);
    //}

    //public func map(source: Accessor, target: [Accessor], conversion: MappingConversion) -> MappingDefinition {
    //    return map([source], target: target, conversion: conversion);
    //}

    //TODO public func map(source: [Accessor], target: Accessor...) -> MappingDefinition {
    //    return map(source, target: target, conversion: nil);
    //}

    //public func map(source: [Accessor], target: Accessor, conversion: MappingConversion) -> MappingDefinition {
    //    return map(source, target: [target], conversion: conversion);
    //}

    //TODOpublic func map(source: Accessor, target: String...) -> MappingDefinition {
    //    return map([source], target: toAccessors(target), conversion: nil);
    //}
/*
public func map(  source : Accessor, String[] target, conversion : MappingConversion) -> MappingDefinition{
    return map(new Accessor[]{source}, toAccessors(target), conversion);
}

public func map( source : Accessor, String target, conversion : MappingConversion) -> MappingDefinition{
    return map(new Accessor[]{source}, toAccessors(new String[]{target}), conversion);
}

public func map(Accessor[] source, String... target) -> MappingDefinition{
    return map(source, toAccessors(target), null);
}

public func map(Accessor[] source, String[] target, conversion : MappingConversion) -> MappingDefinition{
    return map(source, toAccessors(target), conversion);
}

public func map(String[] source, Accessor[] target) -> MappingDefinition{
    return map(toAccessors(source), target, null);
}

public func map(String source, Accessor... target) -> MappingDefinition{
    return map(toAccessors(new String[]{source}), target, null);
}

public func map(String[] source,  target : Accessor) -> MappingDefinition{
    return map(toAccessors(source), new Accessor[]{target}, null);
}

public func map(String[] source, Accessor[] target, conversion : MappingConversion) -> MappingDefinition{
    return map(toAccessors(source), target, conversion);
}

public func map(String source, Accessor[] target, conversion : MappingConversion) -> MappingDefinition{
    return map(toAccessors(new String[]{source}), target, conversion);
}

public func map(String source,  target : Accessor, conversion : MappingConversion) -> MappingDefinition{
    return map(toAccessors(new String[]{source}), new Accessor[]{target}, conversion);
}

public func map(String[] source,  target : Accessor, conversion : MappingConversion) -> MappingDefinition{
    return map(toAccessors(source), new Accessor[]{target}, conversion);
}

public func map(String source, String[] target, conversion : MappingConversion) -> MappingDefinition{
    return map(toAccessors(new String[]{source}), toAccessors(target), conversion);
}

public func map(String source, String target, conversion : MappingConversion)-> MappingDefinition {
    return map(toAccessors(new String[]{source}), toAccessors(new String[]{target}), conversion);
}

public func map(String[] source, String[] target, conversion : MappingConversion) -> MappingDefinition{
    return map(toAccessors(source), toAccessors(target), conversion);
}

public func map(String[] source, String target, conversion : MappingConversion) -> MappingDefinition{
    return map(toAccessors(source), toAccessors(new String[]{target}), conversion);
}

public func map(String[] source, String... target) -> MappingDefinition{
    return map(toAccessors(source), toAccessors(target), null);
}
*/
    public func map(source: String, target: String, conversion: MappingConversion? = nil) -> MappingDefinition {
        return map(toAccessors([source]), target: toAccessors([target]), conversion: conversion);
    }


/* / mapDeep(..) in all kind of combinations

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep( source : Accessor, Accessor... target) {
    return mapDeep(new Accessor[]{source}, target, null);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep( source : Accessor,  target : Accessor, conversion : MappingConversion) {
    return mapDeep(new Accessor[]{source}, new Accessor[]{target}, conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep( source : Accessor, Accessor[] target, conversion : MappingConversion) {
    return mapDeep(new Accessor[]{source}, target, conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(Accessor[] source, Accessor... target) {
    return mapDeep(source, target, null);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(Accessor[] source,  target : Accessor, conversion : MappingConversion) {
    return mapDeep(source, new Accessor[]{target}, conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep( source : Accessor, String... target) {
    return mapDeep(new Accessor[]{source}, toAccessors(target), null);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep( source : Accessor, String[] target, conversion : MappingConversion) {
    return mapDeep(new Accessor[]{source}, toAccessors(target), conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(Accessor[] source, String... target) {
    return mapDeep(source, toAccessors(target), null);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(Accessor[] source, String[] target, conversion : MappingConversion) {
    return mapDeep(source, toAccessors(target), conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String[] source, Accessor[] target) {
    return mapDeep(toAccessors(source), target, null);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String[] source,  target : Accessor) {
    return mapDeep(toAccessors(source), new Accessor[]{target}, null);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String[] source, Accessor[] target, conversion : MappingConversion) {
    return mapDeep(toAccessors(source), target, conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String source, Accessor... target) {
    return mapDeep(toAccessors(new String[]{source}), target, null);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String source, Accessor[] target, conversion : MappingConversion) {
    return mapDeep(toAccessors(new String[]{source}), target, conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String source,  target : Accessor, conversion : MappingConversion) {
    return mapDeep(toAccessors(new String[]{source}), new Accessor[]{target}, conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String[] source,  target : Accessor, conversion : MappingConversion) {
    return mapDeep(toAccessors(source), new Accessor[]{target}, conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String source, String[] target, conversion : MappingConversion) {
    return mapDeep(toAccessors(new String[]{source}), toAccessors(target), conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String source, String target, conversion : MappingConversion) {
    return mapDeep(toAccessors(new String[]{source}), toAccessors(new String[]{target}), conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String[] source, String[] target, conversion : MappingConversion) {
    return mapDeep(toAccessors(source), toAccessors(target), conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String[] source, String target, conversion : MappingConversion) {
    return mapDeep(toAccessors(source), toAccessors(new String[]{target}), conversion);
}

@SuppressWarnings("UnusedDeclaration")
public MappingDefinition mapDeep(String[] source, String... target) {
    return mapDeep(toAccessors(source), toAccessors(target), null);
}
*/

    public func mapDeep(source : String, target : String, conversion: MappingConversion? = nil) -> MappingDefinition {
        return mapDeep(toAccessors([source]), target: toAccessors([target]), conversion: conversion);
    }

    // caching

    public func cache(cache: Bool) -> MappingDefinition {
        self.cache = cache;

        return self;
    }

    // introspection

    public func traceMapping(builder : StringBuilder) -> Void {
        builder.append("Mapping[\(target[0])-\(target[1])] {")

        for operation in operations {
            operation.traceMapping(builder);
        }

        builder.append("}");
    }

    // private

    private func toAccessors(strings: [String]) -> [Accessor] {
        return strings.map({BeanPropertyAccessor(propertyName: $0)})
    }

    private func findMatches(matches: Matches) -> Void {
        // recursion

        if (baseMapping != nil) {
            baseMapping!.findMatches(matches);
        }

        // own matches

        for operation in operations {
            operation.findMatches(self, matches: matches);
        }
    }

    private func createOperations(mapper: Mapper) throws -> [(operations:[Operation<MappingContext>], stackSize:Int)] {
        // conversion are handled separately

        if (conversion != nil) {
            return [([], 0), ([], 0)]
        } // if
        else {
            let matches = Matches();

            findMatches(matches); // find matching properties including base definitions

            return try [
                    matches.makeOperations(mapper, definition: self, direction: MappingDefinition.SOURCE_2_TARGET),
                    matches.makeOperations(mapper, definition: self, direction: MappingDefinition.TARGET_2_SOURCE)
            ]
        } // else
    }

    public func cacheResult() -> Bool {
        return cache;
    }

    func createMapping(mapper: Mapper) throws -> [Mapping] {
        composites = [[], []];

        var operationsAndStackSize = try createOperations(mapper);

        // stupid place, anyway...

        //TODO mapper.setObjectFactory(Mapping.maybeTrace(mapper.getObjectFactory()));
        //TODO mapper.setCompositeFactory(Mapping.maybeTrace(mapper.getCompositeFactory()));

        let finalizers = computeFinalizers();

        return [
                Mapping.maybeTrace(
                        Mapping(mapperDefinition: self, mapper: mapper, direction: MappingDefinition.SOURCE_2_TARGET, conversion: conversion, finalizer: finalizers, sourceBean: target[MappingDefinition.SOURCE], targetBean: target[MappingDefinition.TARGET], operations: operationsAndStackSize[MappingDefinition.SOURCE].operations,
                                stackSize: operationsAndStackSize[MappingDefinition.SOURCE].stackSize, composites: composites[MappingDefinition.SOURCE])),

                Mapping.maybeTrace(
                        Mapping(mapperDefinition: self, mapper: mapper, direction: MappingDefinition.TARGET_2_SOURCE, conversion: conversion, finalizer: finalizers, sourceBean: target[MappingDefinition.TARGET], targetBean: target[MappingDefinition.SOURCE], operations: operationsAndStackSize[MappingDefinition.TARGET].operations,
                                stackSize: operationsAndStackSize[MappingDefinition.TARGET].stackSize, composites: composites[MappingDefinition.TARGET]))
        ]
    }

    private func computeFinalizers() -> [MappingFinalizer] {
        let finalizerList = [MappingFinalizer]();

        /* TODO fetch all finalizers

        for (MappingDefinition definition = self; definition != null; definition = definition.baseMapping) {
            if (definition.finalizer != null)
            finalizerList.add(definition.finalizer);
        } // for

        // remove finalizers that derive from each other

        for  i  in 0..<finalizerList.size() {
            // compare against all more specific finalizers

            for j in i + 1..<finalizerList.size() {
                if (finalizerList.get(j).getClass().isAssignableFrom(finalizerList.get(i).getClass())) {
                    finalizerList.remove(j--);
                }
            } // for
        } // for
        */

        // done

        return finalizerList
    }

    // CustomStringConvertible

    public var debugDescription: String {
        return description
    }

    public var description: String {
        let builder = StringBuilder(string: "MappingDefinition \(self.dynamicType)")

        traceMapping(builder);

        return builder.toString()
    }
}


public class MappingContext {
    // local classes

    public class State {
        // instance data

        private var compositeBuffers: [Mapping.CompositeBuffer]; // for every operation this field will be initialized by the corresponding mapper!
        private var stack: [Any?];

        // constructor

        init(context: MappingContext) {
            compositeBuffers = context.compositeBuffers;
            stack = context.stack;

            // new state

            //TODO FOO context.stack = nil;
        }

        // public

        public func restore(context: MappingContext) -> Void {
            context.compositeBuffers = compositeBuffers;
            context.stack = stack;

            context.decrement();
        }
    }

    // instance data

    private var level: Int = 0;
    private var sourceAndTarget: [AnyObject] = [];
    private var direction: Int;
    internal var mapper: Mapper;
    private var mappedObjects = IdentityMap<AnyObject, AnyObject>()
    private var compositeBuffers: [Mapping.CompositeBuffer] = []; // for every mapping operation this field will be initialized by the corresponding mapper!
    private var stack: [Any?] = [];
    //private var List<ForeignKeyReference> references;
    private var origin: BeanDescriptor.PropertyDescriptor?;
    //private var Keywords keywords;

    // constructor

    init(mapper: Mapper, direction: Int/*, Keywords keywords*/) {
        self.mapper = mapper;
        self.direction = direction;
        //self.keywords = keywords;
    }

    // public

    public func isRoot() -> Bool {
        return level == 1;
    }

    public func increment() -> Void {
        level += 1;
    }

    public func decrement() -> Void {
        level -= 1;
    }

    public func setOrigin(origin: BeanDescriptor.PropertyDescriptor?) -> Void {
        self.origin = origin;
    }

    public func getOrigin() -> BeanDescriptor.PropertyDescriptor? {
        return origin;
    }

    public func setSourceAndTarget(source: AnyObject, target: AnyObject) -> Void {
        sourceAndTarget = [source, target]
    }

    public func getInstance(direction: Int) -> AnyObject {
        return sourceAndTarget[direction];
    }

    public func getDirection() -> Int {
        return direction;
    }

    public func getMapper() -> Mapper {
        return mapper;
    }

//public func void pushReference(ForeignKeyReference reference) {
//    if (references == nil)
//    references = new LinkedList<ForeignKeyReference>();/

//references.add(reference);
//}

    public func remember(source: AnyObject, target: AnyObject) -> MappingContext {
        mappedObjects[source] = target;

        setSourceAndTarget(source, target: target); // also remember the current involved objects!

        return self;
    }

    public func mappedObject(source: AnyObject) -> AnyObject? {
        return mappedObjects[source];
    }

    public func setupComposites(buffers: [Mapping.CompositeBuffer]) -> [Mapping.CompositeBuffer] {
        let saved = compositeBuffers

        compositeBuffers = buffers

        return saved
    }

    public func setup(compositeDefinitions: [MappingDefinition.CompositeDefinition], stackSize: Int) -> [Mapping.CompositeBuffer] {
        let buffers: [Mapping.CompositeBuffer] = compositeDefinitions.map({$0.makeCreator(getMapper())});

        stack = [Any?](count: stackSize, repeatedValue: nil);

        increment();

        return setupComposites(buffers);
    }

    public func getCompositeBuffer(compositeIndex: Int) -> Mapping.CompositeBuffer {
        return compositeBuffers[compositeIndex];
    }

    public func finalizeMapping() -> Void {
        //if (references != nil) {
        /* sort according to the different resolvers

        Map<ReferenceResolver, List<ForeignKeyReference>> mapping = new HashMap<ReferenceResolver, List<ForeignKeyReference>>();

        for (ForeignKeyReference request : references) {
            List<ForeignKeyReference> requests;

            if ((requests = mapping.get(request.getResolver())) == nil)
            mapping.put(request.getResolver(), requests = new LinkedList<ForeignKeyReference>()); // lazy

            requests.add(request);
        } // for

        // for every strategy call the use case with the appropriate arguments and modify the objects

        for (Map.Entry<ReferenceResolver, List<ForeignKeyReference>> referenceResolverListEntry : mapping.entrySet()) {
            List<ForeignKeyReference> requests = referenceResolverListEntry.getValue();
            Map<Object, Object> map = new LinkedHashMap<Object, Object>(requests.size()); // at least self size

            for (ForeignKeyReference request : requests)
            request.getArguments(map);

            ArrayList<Object> keys = new ArrayList<Object>(map.keySet());
            //noinspection unchecked
            Collection<Object> result = referenceResolverListEntry.getKey().resolveReferences(keys);

            // fill map

            Iterator values = result.iterator();
            for (Object key : keys)
            map.put(key, values.next());

            // finalize operations

            for (ForeignKeyReference request : requests)
            request.finalizeOperation(map);
        } // for
        */
        //} // if
    }

    public func push(value: Any?, index: Int) -> Void {
        stack[index] = value
    }

    public func peek(index: Int) -> Any? {
        return stack[index]
    }
}

public class Mapper: ObjectFactory, CompositeFactory, ConversionFactory {
    // constants

    public enum Direction : Int {
        case SOURCE_2_TARGET = 0
        case TARGET_2_SOURCE
    }

    // class methods

    public class func mapping(sourceClass: AnyClass, targetClass: AnyClass) -> MappingDefinition {
        return MappingDefinition(sourceBean: sourceClass, targetBean: targetClass, conversion: nil);
    }

    public class func mapping(sourceClass: AnyClass, targetClass: AnyClass, conversion: MappingConversion?) -> MappingDefinition {
        return MappingDefinition(sourceBean: sourceClass, targetBean: targetClass, conversion: conversion);
    }

    public class func properties(local: Bool = false, except: String...) -> MappingDefinition.PropertyQualifier {
        return MappingDefinition.AllProperties(local: local, except: except);
    }

    // TODO MORE

    // instance data

    var mappings: [IdentityMap<AnyObject, Mapping>] = [IdentityMap<AnyObject, Mapping>(), IdentityMap<AnyObject, Mapping>()]; // [Class|TypeAndOrigin] -> Mapping
    var conversionFactory: ConversionFactory?;
    var definitions: [MappingDefinition]?;
    var objectFactory: ObjectFactory?;
    var compositeFactory: CompositeFactory?;
    //TODO var compositeFactories = IdentityMap<AnyObject, CompositeFactory>(); // TODO ?????
    var bidirectional = true;

    // constructor

    init(mappings: [MappingDefinition]) {
        self.definitions = mappings

        conversionFactory = self
        objectFactory = self
        compositeFactory = self
    }

    // public

    public func createContext(direction: Int) -> MappingContext {
        return MappingContext(mapper: self, direction: direction);
    }

    /**
     * map the specified source object in the specified direction.
     *
     * @param source    the source object
     * @param direction either {@link Mapper#SOURCE_2_TARGET} or {@link Mapper#TARGET_2_SOURCE}
     * @return the result
     */
    public func map(source: AnyObject?, direction: Mapper.Direction, target: AnyObject? = nil) throws -> AnyObject? {
        if (source == nil) {
            return nil; // that's easy ?
        }

        var context = createContext(direction.rawValue);

        defer {
            context.finalizeMapping()
        }

        return try map(source, context: context, target: target);
    }

    public func map(source: AnyObject?, context: MappingContext, target: AnyObject? = nil) throws -> AnyObject? {
        if (source == nil) {
            context.setOrigin(nil);

            return nil; // that's easy ?
        }

        //source = unwrap(source);
        var mapping = try! getMapping(determineClass(source!), direction: context.getDirection(), origin: context.getOrigin());

        context.setOrigin(nil);

        var result : AnyObject? = nil;

        if target != nil {
            result = target
        }
        else {
            result = context.mappedObject(source!)
            if result != nil {
                return result
            }
            else {
                result = mapping.createBean(source!, target: MappingDefinition.TARGET);
            }
        }

        if (mapping.cacheResult()) {
            context.remember(source!, target: result!);
        }

        var state = mapping.setupContext(context); // will create the composite creators...

        defer {
            state.restore(context)
        }

        try mapping.xformTarget(source!, target: result!, context: context);


        return result;
    }

    // internal

    public func determineClass(object: AnyObject) -> AnyClass {
        return object.dynamicType;
    }

    private func registerMappings(mappings: [[Mapping]]) -> Void {
        for mapping: [Mapping] in mappings {
            let source: AnyClass = mapping[0].getSourceBean();
            let target: AnyClass = mapping[0].getTargetBean();

            var viaRelationDescriptors: [BeanDescriptor.PropertyDescriptor]?;

            // source -> target

            viaRelationDescriptors = nil; // TODO mapping[MappingDefinition.SOURCE_2_TARGET].viaRelationDescriptor[MappingDefinition.SOURCE_2_TARGET];

            if (viaRelationDescriptors == nil || viaRelationDescriptors!.count == 0) {
                self.mappings[MappingDefinition.SOURCE_2_TARGET][source] = mapping[MappingDefinition.SOURCE_2_TARGET];
            }

            else {
                //TODO for (BeanDescriptor.RelationDescriptor origin : viaRelationDescriptors) {
                //registerViaMapping(SOURCE_2_TARGET, source, origin, mapping[SOURCE_2_TARGET]);
                //}
            }

// target -> source

            viaRelationDescriptors = nil; //TODOmapping[MappingDefinition.TARGET_2_SOURCE].viaRelationDescriptor[MappingDefinition.TARGET_2_SOURCE];

            if (viaRelationDescriptors == nil || viaRelationDescriptors!.count == 0) {
                self.mappings[MappingDefinition.TARGET_2_SOURCE][target] = mapping[MappingDefinition.TARGET_2_SOURCE];
            }

            else {
                //for (BeanDescriptor.RelationDescriptor origin : viaRelationDescriptors)
                //registerViaMapping(TARGET_2_SOURCE, source, origin, mapping[TARGET_2_SOURCE]);
            }
        } // for
    }

    private func createMappings(definitions: [MappingDefinition]) throws -> [[Mapping]] {
        return try definitions.map({try $0.createMapping(self)});
    }

    public func  specificMapping(source: Accessor , side: Int) -> BeanDescriptor.PropertyDescriptor? {
        var property : BeanDescriptor.PropertyDescriptor;

        if (source is MappingDefinition.BeanPropertyAccessor) {
            property = (source as! MappingDefinition.BeanPropertyAccessor).getProperty();
        }
                //else if (source is MappingDefinition.RelationshipAccessor) {
                //    property = ((source as MappingDefinition.RelationshipAccessor)).relationship;}
        else {
            return nil;
        }

        /* TODO if (side == MappingDefinition.TARGET)
        for definition in definitions)
        for (BeanDescriptor.RelationDescriptor via : definition.via)
        if (property == via)
        return via;//new TypeAndOrigin(definition.target[1 - side], via);
        */
        return property;
    }

    private func initializeMappings(definitions: [MappingDefinition]) throws -> Void {
        conversionFactory = makeConversionFactory();

        mappings[MappingDefinition.SOURCE_2_TARGET] = IdentityMap<AnyObject, Mapping>();
        mappings[MappingDefinition.TARGET_2_SOURCE] = IdentityMap<AnyObject, Mapping>();

        let mappingArray = try createMappings(definitions);

        registerMappings(mappingArray);
    }

    private func makeConversionFactory() -> ConversionFactory {
        return StandardConversionFactory.instance;
    }

    private func setup() throws -> Void {
        try initializeMappings(definitions!);

        definitions = nil;
    }

    private func slowFind(mappings: IdentityMap<AnyObject, Mapping>, clazz: AnyClass?) -> Mapping? {
        if (clazz == AnyObject.self || clazz == nil) {
            return nil; // that's easy
        }

        var mapping = mappings[clazz!];

        if (mapping == nil) {
            // check superclass

            mapping = slowFind(mappings, clazz: clazz!.superclass())

            if (mapping != nil) {
                mappings[clazz!] = mapping; // cache
            }
        } // else

        return mapping!;
    }

    private func getMapping(type: AnyClass, direction: Int, origin: BeanDescriptor.PropertyDescriptor?) throws -> Mapping {
        // lazy initialization

        if definitions != nil {
            try setup()
        }

        var mapping: Mapping?

        // find specific mapping

        if origin != nil {
            /*
            //HashMap<Class,Mapping> matches = (HashMap<Class, Mapping>) mappings[direction].get(origin);

            if (matches == nil)
            mapping = (Mapping)mappings[direction].get(type);

        else {
            mapping = matches.get(type);
            if (mapping == nil) {
                Map<Object,Object> clonedMap = new HashMap<Object,Object>(matches);

                mapping = slowFind(clonedMap, type); // will cache results in specified map
            } // if
        } */
        }
        else {
            mapping = mappings[direction][type]
        }

        if mapping == nil { print("no mapping for type \(type)")
            let clonedMap = mappings[direction] // hmm... clone?
            mapping = slowFind(clonedMap, clazz: type)

            mappings[direction] = clonedMap
        } // if

        if (mapping == nil) {
            throw MapperError.Operation(message: "unknown mapping for class \(type)", mapping: nil, operation : nil, source: nil, target : nil);
        }

        return mapping!;
    }

    public func getObjectFactory() -> ObjectFactory {
        return objectFactory!;
    }

    public func getCompositeFactory() -> CompositeFactory {
        return compositeFactory!;
    }

    // ObjectFactory

    public func createBean(source: AnyObject, clazz: AnyClass) -> AnyObject {
        if let initializable = clazz as? Initializable.Type {
            return initializable.init()
        }
        else {
            fatalError("cannot create a \(Classes.className(clazz))")
        }
    }

    // ConversionFactory

    public func hasConversion(sourceType : Any.Type, targetType : Any.Type) -> Bool {
        return conversionFactory!.hasConversion(sourceType, targetType : targetType)
    }

    public func findConversion(sourceType : Any.Type, targetType : Any.Type) -> Conversion? {
        return conversionFactory!.findConversion(sourceType, targetType : targetType)
    }

    public func getConversion(sourceType : Any.Type, targetType : Any.Type) throws -> Conversion {
        return try conversionFactory!.getConversion(sourceType, targetType : targetType)
    }

    // CompositeFactory

    public func createComposite(clazz: AnyClass, arguments: AnyObject...) -> AnyObject {
        return (clazz as! NSObject.Type).init() //"clazz.init()"// TODO
    }
}


public class Mapping: XFormer<MappingContext>, CustomStringConvertible {
    // local class

    private static var DEPTH = ThreadLocal<Int>(generator: {0})

    class func increment() {
        DEPTH.set(DEPTH.get() + 1)
    }

    class func decrement() {
        DEPTH.set(DEPTH.get() - 1)
    }

    private class func indentation() -> String {
        return String(count: DEPTH.get(), repeatedValue: Character("\t"))
    }

    private class func trace(message : String) {
        print(indentation() + message)
    }

    public class TracingMapping : Mapping {
        // local classes

        public class LoggingProperty : Property<MappingContext> {
            // instance data

            var sourceProperty: Property<MappingContext>;
            var targetProperty: Property<MappingContext>;

            // constructor

            init(source: Property<MappingContext>, target: Property<MappingContext>) {
                self.sourceProperty = source;
                self.targetProperty = target;
            }

            // implement Property

            override public func get(object: AnyObject!, context: MappingContext) throws -> Any? {
                let value =  try sourceProperty.get(object, context: context);

                Mapping.trace("get \(sourceProperty) = \(value)");

                return value
            }

            override public func set(object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
                if (targetProperty.description.hasPrefix("Push")) {
                    Mapping.trace("\(targetProperty) \(sourceProperty)=\(value)")
                }
                else {
                    Mapping .trace("set \(targetProperty) = \(value)")
                }

                try targetProperty.set(object, value: value, context: context);
            }
        }

        // instance data

        private var originalMapping : Mapping;

        // constructor

        override init(mapping : Mapping ) {
            originalMapping = mapping;

            super.init(mapping: mapping);

            //viaRelationDescriptor = mapping.viaRelationDescriptor;

            patchOperations();
        }

        // private

        private func patchOperations() -> Void {
            for operation in operations {
                operation.source = LoggingProperty(source: operation.source, target: operation.target);
                operation.target = LoggingProperty(source: operation.source, target: operation.target);
            } // for
        }

        // override

        override public func createBean(source: AnyObject, target: Int) -> AnyObject {
            return originalMapping.createBean(source, target: target); // ?
        }

        override public func setupContext(context : MappingContext ) -> MappingContext.State {
            return originalMapping.setupContext(context);
        }

        override public func xformTarget(source: AnyObject, target: AnyObject,  context : MappingContext ) throws -> Void {
            Mapping.trace("map \(source.dynamicType) -> \(target.dynamicType) {")

            Mapping.increment();

            defer {Mapping.decrement(); Mapping.trace("}") }

            try originalMapping.xformTarget(source, target: target, context: context);

            //if (originalMapping.finalizer != null) {
            //    Tracer.trace("apply finalizer");
            //} // if

        }

// override

//@Override
//public String toString() {
//    return originalMapping.toString();
//}
    }

    // class funcs

    class func maybeTrace(mapping: Mapping) -> Mapping {
        if Tracer.ENABLED && Tracer.getTraceLevel("mapper") == .FULL {
            return TracingMapping(mapping: mapping)
        }
        else {
            return mapping;
        }
    }

    class func maybeTrace(objectFactory: ObjectFactory) -> ObjectFactory {
        return objectFactory; // TODO
    }

    class func maybeTrace(compositeFactory: CompositeFactory) -> CompositeFactory {
        return compositeFactory; // TODO
    }

    // local classes


    public class CompositeBuffer {
        // static methods

        class func allNull(args: [Any?]) -> Bool {
            for arg in args {
                if (arg != nil) {
                    return false;
                }
            }

            return true;
        }

        // instance data

        var mapper: Mapper;
        var nSuppliedArgs: Int;
        var arguments: [Any?];
        var outerComposite: Int;
        var outerIndex: Int;

        // constructor

        init(mapper: Mapper, nargs: Int, outerComposite: Int, outerIndex: Int) {
            self.mapper = mapper;
            self.nSuppliedArgs = nargs;
            self.arguments = [Any?](count: nargs, repeatedValue: nil);
            self.outerComposite = outerComposite;
            self.outerIndex = outerIndex;
        }

        // public

        public func rememberCompositeArgument(accessor: Accessor, rootProperty: Accessor, index: Int, instance: AnyObject, value: Any?, mappingContext: MappingContext) throws -> Void {
            // noop
        }
    }

    public class MutableCompositeBuffer: CompositeBuffer {
        // instance data

        private var clazz: AnyClass;
        private var accessors: [Accessor?];
        private var parentAccessor: Accessor;

        // constructor

        init(mapper: Mapper, clazz: AnyClass, nargs: Int, outerComposite: Int, outerIndex: Int, parentAccessor: Accessor) {


            self.clazz = clazz;
            self.parentAccessor = parentAccessor;
            self.accessors = [Accessor?](count: nargs, repeatedValue: nil);

            super.init(mapper: mapper, nargs: nargs, outerComposite: outerComposite, outerIndex: outerIndex);
        }

        // public

        override public func rememberCompositeArgument(accessor: Accessor, rootProperty: Accessor, index: Int, instance: AnyObject, value: Any?, mappingContext: MappingContext) throws -> Void {
            arguments[index] = value;
            accessors[index] = accessor

            // are we done?

            nSuppliedArgs += 1

            if (nSuppliedArgs == arguments.count) {
                // create composite

                let composite: AnyObject? = CompositeBuffer.allNull(arguments) ? nil : mapper.getObjectFactory().createBean("nil", clazz: clazz); // TODO WTF

                // set the values

                if (composite != nil) {
                    for i in 0 ..< accessors.count {
                        if (accessors[i] != nil) {
                            do {
                                try accessors[i]!.setValue(composite!, value: arguments[i]!, mappingContext: mappingContext);
                            }
                            catch {
                                throw MapperError.Operation(message: "could not set composite value \(arguments[i]) in the class \(composite)", mapping: nil, operation : nil, source: nil, target : nil);
                            }
                        }
                    }
                }

                // are we nested?

                if (outerComposite != -1) {
                    try mappingContext.getCompositeBuffer(outerComposite).rememberCompositeArgument(rootProperty/*parentAccessor*/, rootProperty: parentAccessor/*rootProperty*/, index: outerIndex, instance: instance, value: composite, mappingContext: mappingContext);
                }

                else {
                    // simply set the instance in the target object

                    do {
                        try rootProperty.setValue(instance, value: composite!, mappingContext: mappingContext);
                    }
                    catch {
                        throw MapperError.Operation(message: "could not set composite value \(composite) in \(instance)", mapping: nil, operation : nil, source: nil, target : nil);
                    }
                } // else
            } // if
        }
    }

    public class ImmutableCompositeBuffer: CompositeBuffer {
        // instance data

        private var clazz: AnyClass;
        var parentAccessor: Accessor;

        // constructor

        init(mapper: Mapper, clazz: AnyClass, nargs: Int, outerComposite: Int, outerIndex: Int, parentAccessor: Accessor) {
            self.clazz = clazz;
            self.parentAccessor = parentAccessor;

            super.init(mapper: mapper, nargs: nargs, outerComposite: outerComposite, outerIndex: outerIndex);
        }

        // private


        // public

        override public func rememberCompositeArgument(accessor: Accessor, rootProperty: Accessor, index: Int, instance: AnyObject, value: Any?, mappingContext: MappingContext) throws -> Void {
            /*arguments[index] = value;

            // are we done?

            if (++nSuppliedArgs == arguments.length) {
                // create composite


                Object composite = allNull(arguments) ? nil : mapper.getCompositeFactory().createComposite(clazz, arguments);

                // are we nested?

                if (outerComposite != -1)
                mappingContext.getCompositeBuffer(outerComposite).rememberCompositeArgument(rootProperty/*parentAccessor*/, parentAccessor/*rootProperty*/, outerIndex, instance, composite, mappingContext);

            else {
                // simply set the instance in the target object

                try {
                    rootProperty.setValue(instance, composite, mappingContext);
                }
                catch (Throwable e) {
                    throw new MapperDefinitionException("could not set composite value " + instance + " in the class " + instance.getClass().getSimpleName(), e);
                } TODO
            } // else
        } // if
        */
        }
    }

    // instance data

    private var mapper: Mapper;
    private var beans: [AnyClass];
    private var composites: [MappingDefinition.CompositeDefinition];
    private var objectFactory = [ObjectFactory?](count: 2, repeatedValue: nil);
    private var stackSize: Int = 0;
    private var finalizer: [MappingFinalizer] = [];
    private var cache: Bool;
    //public var viaRelationDescriptor = new BeanDescriptor.PropertyDescriptor[2][];

    // constructor

    init(mapping: Mapping) {
        self.mapper = mapping.mapper;
        self.beans = mapping.beans;
        self.composites = mapping.composites;
        self.cache = mapping.cache;

        super.init(operations: mapping.operations);
    }

    init(mapperDefinition: MappingDefinition, mapper: Mapper, direction: Int, conversion: MappingConversion?, finalizer: [MappingFinalizer], sourceBean: AnyClass, targetBean: AnyClass, operations: [Operation<MappingContext>], stackSize: Int, composites: [MappingDefinition.CompositeDefinition]) {
        self.finalizer = finalizer;
        self.mapper = mapper;
        self.stackSize = stackSize;
        self.beans = [sourceBean, targetBean];
        self.composites = composites;
        self.cache = mapperDefinition.cacheResult();

        super.init(operations: operations);

        // copy existing mappings...

        if (direction == MappingDefinition.SOURCE_2_TARGET) {
            objectFactory[MappingDefinition.SOURCE] = mapperDefinition.getObjectFactories()[MappingDefinition.SOURCE];
            objectFactory[MappingDefinition.TARGET] = mapperDefinition.getObjectFactories()[MappingDefinition.TARGET];
        }
        else {
            objectFactory[MappingDefinition.TARGET] = mapperDefinition.getObjectFactories()[MappingDefinition.SOURCE];
            objectFactory[MappingDefinition.SOURCE] = mapperDefinition.getObjectFactories()[MappingDefinition.TARGET];
        }

        // ss
        //TODO self.viaRelationDescriptor[direction] = mapperDefinition.via;

        if (conversion == nil) {
            if (objectFactory[MappingDefinition.SOURCE] == nil) {
                objectFactory[MappingDefinition.SOURCE] = mapper;
            }

            if (objectFactory[MappingDefinition.TARGET] == nil) {
                objectFactory[MappingDefinition.TARGET] = mapper;
            } // if
            else {
                objectFactory[MappingDefinition.SOURCE] = nil; // direction == Mapper.SOURCE_2_TARGET ? new ConvertSourceObjectFactory(conversion) : new ConvertTargetObjectFactory(conversion);
                //TODO objectFactory[Mapper.TARGET] = direction == Mapper.SOURCE_2_TARGET ? ConvertSourceObjectFactory(conversion!) : ConvertTargetObjectFactory(conversion!);
            } // else
        }
    }

    public func setupContext(context: MappingContext) -> MappingContext.State {
        let state = MappingContext.State(context: context);

        context.setup(composites, stackSize: stackSize);

        return state;
    }


    public func getBeans() -> [AnyClass] {
        return beans;
    }

    public func getSourceBean() -> AnyClass {
        return beans[0];
    }

    func getTargetBean() -> AnyClass {
        return beans[1];
    }

    func createBean(source: AnyObject, target: Int) -> AnyObject {
        return objectFactory[target]!.createBean(source, clazz: beans[target]);
    }

    func cacheResult() -> Bool {
        return self.cache;
    }

    // override Transformer

    // add some context information...

    override public func xformTarget(source: AnyObject, target: AnyObject, context: MappingContext) throws -> Void {
        for operation in operations {
            do {

                let value = try operation.source.get(source, context: context);

                try operation.target.set(target, value: value, context: context);
            }
            catch MapperError.Operation(let message, _, let operation, let source, let target) {
                throw MapperError.Operation(message: message, mapping: self, operation : operation, source: source, target : target);
            }
            catch  {
                throw MapperError.Operation(message: "mapping error", mapping: self, operation : operation as? MappingOperation, source: source, target : target);
            }
        } // for

        // finalizer?

        let mappingContext = context as MappingContext;

        for aFinalizer in finalizer {
            if (mappingContext.getDirection() == MappingDefinition.SOURCE_2_TARGET) {
                aFinalizer.finalizeTarget(source, target: target, context: mappingContext);
            }

            else {
                aFinalizer.finalizeSource(source, target: target, context: mappingContext); }
        }
    }

    // CustomStringConvertible

    public var description : String {
        let builder = StringBuilder(string: "Mapping[\(beans[0])-\(beans[1])]")

        for operation in operations {
            builder.append("   {\(operation.source)-\(operation.target)}")
        }

        return builder.toString()
    }
}

// Mapping

// Operations

public class AccessorValue<CONTEXT:MappingContext>: Property<CONTEXT> {
    // instance data

    var accessor: Accessor;

    // constructor

    init(accessor: Accessor) {
        self.accessor = accessor
    }

    // public


    public override func get(object: AnyObject!, context: CONTEXT) throws -> Any? {
        return try accessor.getValue(object);
    }


    override public func set(object: AnyObject!, value: Any?, context: CONTEXT) throws -> Void {
        try accessor.setValue(object, value: value, mappingContext: context);
    }

    // override

    override public var description : String {
        return accessor.description
    }
}

public class MapCollection2Collection : AccessorValue<MappingContext> {
    // instance data

    var origin: BeanDescriptor.PropertyDescriptor? = nil

    // init

    init(sourceType: Any.Type, targetType: Any.Type, accessor: Accessor , origin: BeanDescriptor.PropertyDescriptor? ) {
        super.init(accessor: accessor)
    }

    // override

    override public func set(object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
        let mapper = context.getMapper();

        if value != nil {
            var result = try accessor.getValue(object) as! Array<AnyObject> // NSArray();//target.create(size); TODO WTF!
            let array = value as! Array<AnyObject>

            for element in array {
                context.setOrigin(origin);
                //try {
                result.append(try mapper.map(element, context: context)!);
                //}
                //finally {
                context.setOrigin(nil);
                //}
            }

            try super.set(object, value: result, context: context);
        }
        //try accessor.setValue(object, value: value, mappingContext: context);
    }
}

public class MapDeep<CONTEXT:MappingContext>: AccessorValue<CONTEXT> {
    // instance data

    private var origin: BeanDescriptor.PropertyDescriptor?;

    // constructor

    /**
     * create a new MapProperty.
     *
     * @param property the bean property
     * @param origin   a {@link BeanDescriptor.PropertyDescriptor}
     */
    init(property: Accessor, origin: BeanDescriptor.PropertyDescriptor?) {
        self.origin = origin;

        super.init(accessor: property);
    }

    // override BeanProperty

    override public func set(instance: AnyObject!, value: Any?, context: CONTEXT) throws -> Void {
        context.setOrigin(origin);

        defer {
            context.setOrigin(nil);
        }

        let value = try context.getMapper().map((value as! AnyObject), context: context);

        try super.set(instance, value: value, context: context);
    }
}

public class PeekValue: Property<MappingContext> {
    // instance data

    var index: Int;

    // constructor

    init(index: Int) {
        self.index = index;
    }

    // implement Property

    override public func get(object: AnyObject!, context: MappingContext) throws -> Any? {
        return context.peek(index)
    }

    override public func set(object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
        fatalError("not possible")
    }

    // override

    override public var description : String {
        return "Peek(\(index)";
    }
}

public class PeekValueProperty: PeekValue {
    // instance data

    private var property: Property<MappingContext>;

    // constructor

    init(int index: Int, property: Property<MappingContext>) {
        self.property = property;

        super.init(index: index);
    }

    // implement Property

    override public func get(object: AnyObject!, context: MappingContext) throws -> Any? {
        let value = try super.get(object, context: context)

        return value != nil ? try property.get(value as! AnyObject, context: context)  :  nil
    }

    override public func set(object: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
        fatalError("not possible");
    }

    // override

    override public var description : String {
        return "Peek(\(index).\(property)";
    }
}

public class PushValueProperty: Property<MappingContext> {
    // instance data

    private var index: Int;

    // constructor

    init(index: Int) {
        self.index = index;
    }

    // implement Property

    override public func get(object: AnyObject!, context: MappingContext) -> Any? {
        fatalError("not possible");
    }


    override public func set(object: AnyObject!, value: Any?, context: MappingContext) -> Void {
        context.push(value, index: index)
    }

    // override

    override public var description : String {
        return "Push";
    }
}

public class SetCompositeArgument: Property<MappingContext> {
    // instance data

    private var rootAccessor: Accessor;
    private var compositeIndex: Int;
    private var argumentIndex: Int;
    private var accessor: Accessor;

    // constructor

    init(accessor: Accessor, rootAccessor: Accessor, compositeIndex: Int, argumentIndex: Int) {
        self.rootAccessor = rootAccessor;
        self.compositeIndex = compositeIndex;
        self.argumentIndex = argumentIndex;
        self.accessor = accessor;
    }

    // implement Property

    override public func get(instance: AnyObject!, context: MappingContext) throws -> Any? {
        fatalError("wrong direction"); // return property.getValue(instance);
    }

    override public func set(instance: AnyObject!, value: Any?, context: MappingContext) throws -> Void {
        // remember value at index index
        // the instance is irrelevant!

        try context.getCompositeBuffer(compositeIndex).rememberCompositeArgument(accessor, rootProperty: rootAccessor, index: argumentIndex, instance: instance, value: value, mappingContext: context);
    }

    // override

    override public var description : String {
        return "\(rootAccessor.getType()).\(rootAccessor.getName())[\(argumentIndex)]";
    }
}
