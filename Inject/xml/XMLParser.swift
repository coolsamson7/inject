//
//  XMLParser.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class XMLParser: NSObject {
    // local classes
    
   public class ClassDefinition {
        // local class Name {
        
        class PropertyDefinition {
            // instance data
            
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
            
            // internal
            
            func set(object : AnyObject, value : String) throws -> Void {
                var val : AnyObject = value;
                if conversion != nil {
                    val = try conversion!(object: val)
                }
                
                try property.set(object, value: val)
            }
        }
        
        // instance data
        
        var clazz : BeanDescriptor
        var element  : String
        var properties = [String:PropertyDefinition]()
        
        // init
        
        init(clazz: AnyClass, element : String) {
            self.clazz = BeanDescriptor.forClass(clazz)
            self.element = element
        }
        
        // internal
        
        // fluent
        
        func property(property : String, xml : String? = nil, conversion : Conversion? = nil) throws -> ClassDefinition {
            let definition = try PropertyDefinition(bean: clazz, propertyName: property, xml: xml, conversion: conversion)
            
            properties[definition.xml] = definition
            
            return self
        }
        
        /*func property(property : String, xml : String, conversion : Conversion) throws -> ClassDefinition {
         let definition = try PropertyDefinition(bean: clazz, propertyName: property, xml: xml, conversion: conversion)
         
         properties[definition.xml] = definition
         
         return self
         }*/
    }
    
    // internal
    
    class State : NSObject, NSXMLParserDelegate {
        // MARK: locales classes
        
        class Operation {
            func canHandle(element : String) -> Bool {
                return false
            }
            
            func handle(elementName : String) -> Operation? {
                return nil
            }
            
            func processAttributes(parser: NSXMLParser, attributes : [String : String]) throws -> Void {
            }
            
            func characters(string : String) throws -> Void {
            }
            
            func popped(state : State) -> Void {
                
            }
        }
        
        class ClassOperation : Operation {
            // instance data
            
            var definition : ClassDefinition
            var instance : AnyObject
            var parent : ClassOperation?
            
            // init
            
            init(parent : ClassOperation?, definition : ClassDefinition) {
                self.parent = parent
                self.definition = definition
                
                instance = definition.clazz.create()
            }
            
            // func
            
            override func processAttributes(parser: NSXMLParser, attributes : [String : String]) throws -> Void {
                for (key, value) in attributes {
                    if let property = definition.properties[key] {
                        do {
                            try property.set(instance, value: value)
                        }
                        catch ConversionErrors.ConversionException(let value, let targetType, _) {
                            throw ConversionErrors.ConversionException(value: value, targetType: targetType, context: "[\(parser.lineNumber):\(parser.columnNumber)]" )
                        }
                        //catch {
                        //    throw error
                        //}
                    }
                    else if instance is AttributeContainer {
                        //TODO attributeContainer[key] = value
                    }
                    else {
                        throw ApplicationContextErrors.ParseError(message: "unknown xml attribute \"\(key)\" in [\(parser.lineNumber):\(parser.columnNumber)]")
                    }
                }
            }
            
            override func canHandle(element : String) -> Bool {
                return definition.properties[element] != nil
            }
            
            override func handle(elementName : String) -> Operation? {
                return PropertyOperation(parent: self, definition: definition.properties[elementName]!)
            }
            
            override func popped(state : State) {
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
            // instance data
            
            var definition : ClassDefinition.PropertyDefinition
            var parent: ClassOperation
            
            // init
            
            init(parent: ClassOperation, definition : ClassDefinition.PropertyDefinition) {
                self.parent = parent
                self.definition = definition
            }
            
            // override
            
            override func characters(string : String) throws -> Void {
                try definition.set(parent.instance, value: string)
            }
        }
        
        // instance data
        
        var parser : XMLParser
        var operations = [Operation]()
        var currentOperation : Operation? = nil
        var currentClass : ClassOperation? = nil
        var root : AnyObject? = nil
        var _error : XMLParserErrors? = nil
        
        // init
        
        init(parser : XMLParser) {
            self.parser = parser
        }
        
        // internal
        
        func reportError(error : XMLParserErrors) {
            if self._error == nil {
                self._error = error
            }
        }
        
        func reportParseError(error : NSError) {
            if self._error == nil {
                self._error = XMLParserErrors.ParseException(message: error.description)
            }
        }
        
        func reportValidationError(error : NSError) {
            if self._error == nil {
                self._error = XMLParserErrors.ValidationException(message: error.description)
            }
        }
        
        func push(operation : Operation) -> Void {
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
        internal func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
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
                                if let colon = qName!.rangeOfString(":", range: qName!.startIndex..<qName!.endIndex) {
                                    let namespace = qName![qName!.startIndex..<colon.startIndex]
                                    
                                    namespaceAware.namespace = namespace
                                }
                            }
                            
                            if var originAware = currentClass!.instance as? OriginAware {
                                originAware.origin = Origin(line: parser.lineNumber, column: parser.columnNumber)
                            }
                            
                            push(currentClass!)
                        }
                        else {
                            throw XMLParserErrors.ParseException(message: "unknown element \(qName!) in line \(parser.lineNumber)")
                        }
                    }
                    
                    try currentOperation!.processAttributes(parser, attributes: attributeDict)
                    
                }
                catch XMLParserErrors.ParseException(let message) {
                    reportError(XMLParserErrors.ParseException(message: message))
                }
                catch {
                    reportError(XMLParserErrors.Exception(message: "\(error) in line \(parser.lineNumber)"))
                }
            }
        }
        
        // didEndElement
        internal func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if _error == nil {
                pop()
            }
        }
        
        // foundCharacters
        internal func parser(parser: NSXMLParser, foundCharacters string: String) {
            if _error == nil {
                do {
                    try currentOperation!.characters(string)
                }
                catch XMLParserErrors.ParseException(let message) {
                    reportError(XMLParserErrors.ParseException(message: message))
                }
                catch {
                    reportError(XMLParserErrors.Exception(message: "\(error)"))
                }
            }
        }
        
        //parseErrorOccurred
        internal func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
            reportParseError(parseError)
        }
        
        //validationErrorOccurred
        internal func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError) {
            reportValidationError(validationError)
        }
    }
    
    // instance data
    
    var classes = [String:ClassDefinition]()
    
    // register stuff
    
    func register(classes : ClassDefinition...) {
        for clazz in classes {
            self.classes[clazz.element] = clazz
        }
    }
    
    // public
    
    func parse(data : NSData) throws -> AnyObject? {
        let parser = NSXMLParser(data: data)
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
