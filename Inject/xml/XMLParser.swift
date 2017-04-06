//
//  XMLParser.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

open class XMLParser: NSObject {
    // local classes
    
   open class ClassDefinition {
        // local class Name {
        
        class PropertyDefinition {
            // MARK: instance data
            
            var property  : BeanDescriptor.PropertyDescriptor
            var xml: String
            var conversion : Conversion?
            
            // init
            
            init(bean : BeanDescriptor, propertyName  : String, xml : String? = nil, conversion : Conversion? = nil) throws {
                self.property = try bean.getProperty(propertyName)
                self.xml = xml != nil ? xml! : propertyName
                
                if conversion != nil {
                    self.conversion = conversion
                }
                else if property.getPropertyType() != String.self && property.getPropertyType() != AnyObject.self {
                    self.conversion = try StandardConversionFactory.instance.getConversion(String.self, targetType: property.getPropertyType())
                }
            }
            
            // MARK: internal
            
            func set(_ object : AnyObject, value : String) throws -> Void {
                var val : Any = value;
                if conversion != nil {
                    val = try conversion!(object: val)
                }
                
                try property.set(object, value: val)
            }
        }
        
        // MARK: instance data
        
        var clazz : BeanDescriptor
        var element  : String
        var properties = [String:PropertyDefinition]()
        
        // init
        
        init(clazz: AnyClass, element : String) {
            self.clazz = try! BeanDescriptor.forClass(clazz)
            self.element = element
        }
        
        // MARK: internal
        
        // fluent
        
        func property(_ property : String, xml : String? = nil, conversion : Conversion? = nil) throws -> Self {
            let definition = try PropertyDefinition(bean: clazz, propertyName: property, xml: xml, conversion: conversion)
            
            properties[definition.xml] = definition
            
            return self
        }
    }
    
    // MARK: internal
    
    class State : NSObject, XMLParserDelegate {
        // MARK: locales classes
        
        class Operation {
            func canHandle(_ element : String) -> Bool {
                return false
            }
            
            func handle(_ elementName : String) -> Operation? {
                return nil
            }
            
            func processAttributes(_ parser: Foundation.XMLParser, attributes : [String : String]) throws -> Void {
            }
            
            func characters(_ string : String) throws -> Void {
            }
            
            func popped(_ state : State) -> Void {
                
            }
        }
        
        class ClassOperation : Operation {
            // MARK: instance data
            
            var definition : ClassDefinition
            var instance : AnyObject
            var parent : ClassOperation?
            
            // init
            
            init(parent : ClassOperation?, definition : ClassDefinition) {
                self.parent = parent
                self.definition = definition
                
                instance = try! definition.clazz.create()
            }
            
            // func
            
            override func processAttributes(_ parser: Foundation.XMLParser, attributes : [String : String]) throws -> Void {
                for (key, value) in attributes {
                    if let property = definition.properties[key] {
                        do {
                            try property.set(instance, value: value)
                        }
                        catch ConversionErrors.conversionException(let value, let targetType, _) {
                            throw ConversionErrors.conversionException(value: value, targetType: targetType, context: "[\(parser.lineNumber):\(parser.columnNumber)]" )
                        }
                        //catch {
                        //    throw error
                        //}
                    }
                    else if instance is AttributeContainer {
                        //TODO attributeContainer[key] = value
                    }
                    else {
                        throw EnvironmentErrors.parseError(message: "unknown xml attribute \"\(key)\" in [\(parser.lineNumber):\(parser.columnNumber)]")
                    }
                }
            }
            
            override func canHandle(_ element : String) -> Bool {
                return definition.properties[element] != nil
            }
            
            override func handle(_ elementName : String) -> Operation? {
                return PropertyOperation(parent: self, definition: definition.properties[elementName]!)
            }
            
            override func popped(_ state : State) {
                state.currentClass = parent
                if parent == nil {
                    state.root = instance
                }
                else {
                    if let parentNode = parent!.instance as? Ancestor {
                        parentNode.addChild(instance)
                    }
                }
            }
        }
        
        class PropertyOperation : Operation {
            // MARK: instance data
            
            var definition : ClassDefinition.PropertyDefinition
            var parent: ClassOperation
            
            // init
            
            init(parent: ClassOperation, definition : ClassDefinition.PropertyDefinition) {
                self.parent = parent
                self.definition = definition
            }
            
            // override
            
            override func characters(_ string : String) throws -> Void {
                try definition.set(parent.instance, value: string)
            }
        }
        
        // MARK: instance data
        
        var parser : XMLParser
        var operations = [Operation]()
        var currentOperation : Operation? = nil
        var currentClass : ClassOperation? = nil
        var root : AnyObject? = nil
        var _error : XMLParserErrors? = nil
        
        // init

        internal init(parser : XMLParser) {
            self.parser = parser
        }
        
        // MARK: internal
        
        func reportError(_ error : XMLParserErrors) {
            if self._error == nil {
                self._error = error
            }
        }
        
        func reportParseError(_ error : NSError) {
            if self._error == nil {
                self._error = XMLParserErrors.parseException(message: error.description)
            }
        }
        
        func reportValidationError(_ error : NSError) {
            if self._error == nil {
                self._error = XMLParserErrors.validationException(message: error.description)
            }
        }
        
        func push(_ operation : Operation) -> Void {
            operations.append(operation)
            currentOperation = operation
        }
        
        func pop() -> Operation? {
            let operation : Operation? = operations.popLast();
            
            operation!.popped(self)
            
            currentOperation = operations.last
            
            return operation;
        }
        
        // NSXMLParserDelegate
        
        // didStartElement
        internal func parser(_ parser: Foundation.XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
            if _error == nil {
                do {
                    if currentOperation != nil && currentOperation!.canHandle(elementName) {
                        push(currentOperation!.handle(elementName)!)
                    }
                    else {
                        let definition = self.parser.classes[qName!]//elementName
                        if definition != nil {
                            currentClass = ClassOperation(parent: currentClass, definition: definition!)
                            
                            if var namespaceAware = currentClass!.instance as? NamespaceAware {
                                if let colon = qName!.range(of: ":", range: qName!.startIndex..<qName!.endIndex) {
                                    let namespace = qName![qName!.startIndex..<colon.lowerBound]
                                    
                                    namespaceAware.namespace = namespace
                                }
                            }
                            
                            if var originAware = currentClass!.instance as? OriginAware {
                                originAware.origin = Origin(file: "", line: parser.lineNumber, column: parser.columnNumber)
                            }
                            
                            push(currentClass!)
                        }
                        else {
                            throw XMLParserErrors.parseException(message: "unknown element \(qName!) in line \(parser.lineNumber)")
                        }
                    }
                    
                    try currentOperation!.processAttributes(parser, attributes: attributeDict)
                    
                }
                catch XMLParserErrors.parseException(let message) {
                    reportError(XMLParserErrors.parseException(message: message))
                }
                catch {
                    reportError(XMLParserErrors.exception(message: "\(error) in line \(parser.lineNumber)"))
                }
            }
        }
        
        // didEndElement
        internal func parser(_ parser: Foundation.XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if _error == nil {
                pop()
            }
        }
        
        // foundCharacters
        internal func parser(_ parser: Foundation.XMLParser, foundCharacters string: String) {
            if _error == nil {
                do {
                    try currentOperation!.characters(string)
                }
                catch XMLParserErrors.parseException(let message) {
                    reportError(XMLParserErrors.parseException(message: message))
                }
                catch {
                    reportError(XMLParserErrors.exception(message: "\(error)"))
                }
            }
        }
        
        //parseErrorOccurred
        internal func parser(_ parser: Foundation.XMLParser, parseErrorOccurred parseError: Error) {
            reportParseError(parseError as! NSError)
        }
        
        //validationErrorOccurred
        internal func parser(_ parser: Foundation.XMLParser, validationErrorOccurred validationError: Error) {
            reportValidationError(validationError as! NSError)
        }
    }

    // MARK: static funcs

    open static func mapping(_ clazz: AnyClass, element: String) -> ClassDefinition {
        let result = ClassDefinition(clazz: clazz, element: element)

        return result
    }

    // MARK: instance data
    
    var classes = [String:ClassDefinition]()
    
    // register stuff
    
    open func register(_ classes : ClassDefinition...) -> Self {
        for clazz in classes {
            self.classes[clazz.element] = clazz
        }

        return self
    }
    
    // MARK: public
    
    open func parse(_ data : Data) throws -> AnyObject? {
        let parser = Foundation.XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        
        let state = State(parser: self)
        parser.delegate = state
        
        if parser.parse() {
            if state._error != nil {
                throw state._error!
            }
            else {
                return state.root
            }
        }
        else {
            throw state._error!
        }
    }
}
