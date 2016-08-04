//
//  ConfigurationNamespaceHandler.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class ConfigurationNamespaceHandler : NamespaceHandler {
    // local classes
    
    // the source
    
    class ConfigurationNamespaceHandlerSource : AbstractConfigurationSource {
        // instance data
        
        var items : [ConfigurationItem] = []
        
        // init
        
        override init() {
            super.init()
        }
        
        init(name : String, items : [ConfigurationItem] ) {
            super.init(url: name, mutable: false, canOverrule: true)
            
            self.items = items;
        }
        
        // override
        
        override func load(configurationManager : ConfigurationManager) throws -> Void {
            for item in items {
                try configurationManager.configurationAdded(item, source: self)
            }
        }
    }
    
    // nodes
    
    
    @objc(Configuration)
    class Configuration : NSObject, Ancestor, NamespaceAware, OriginAware {
        // instance data
        
        var _namespace : String?
        var _origin : Origin?
        var configurationNamespace : String?
        
        var definitions = [Define]()
        
        // Ancestor
        
        func addChild(child : AnyObject) -> Void {
            if let define = child as? Define {
                definitions.append(define)
            }
        }
        
        // OriginAware
        
        var origin : Origin? {
            get {
                return _origin
            }
            set {
                _origin = newValue
            }
        }
        
        // NamespaceAware
        
        var namespace : String? {
            get {
                return _namespace
            }
            set {
                _namespace = newValue
            }
        }
    }
    
    @objc(Define)
    class Define : NSObject {
        // instance data
        
        var namespace : String?
        var key : String?
        var type : String?
        var value : String?
        
    }
    
    // init
    
    init() {
        super.init(namespace: "")
    }
    
    override init(namespace : String) {
        super.init(namespace: namespace)
    }
    
    // override
    
    override func register(loader : XMLEnvironmentLoader) throws {
        try super.register(loader)

        try loader.register(
            mapping(Configuration.self, element: "configuration:configuration")
                .property("configurationNamespace", xml: "namespace"),
            
            mapping(Define.self, element: "configuration:define")
                .property("namespace")
                .property("key")
                .property("type")
                .property("value")
        )
    }
    
    override func process(namespaceAware : NamespaceAware, inout beans : [Environment.BeanDeclaration]) throws -> Void {
        if let configuration = namespaceAware as? Configuration {
            let url = "configuration snippets"
            let namespace = configuration.configurationNamespace
            
            var items : [ConfigurationItem] = []
            
            // iterate
            
            for define in configuration.definitions {
                // inherit namespace
                
                if define.namespace == nil {
                    define.namespace = namespace != nil ? namespace : ""
                }
                
                if define.key == nil {
                    ConfigurationErrors.ParseError(message: "missing key");
                }
                
                if define.value == nil {
                    ConfigurationErrors.ParseError(message: "missing value");
                }
                
                var type : Any.Type;
                
                switch define.type! {
                case "String":
                    type = String.self
                case "Int":
                    type = Int.self
                case "Bool":
                    type = Bool.self
                default:
                    throw ConfigurationErrors.ParseError(message: "unknown type \"\(define.type)\"");
                }
                
                let item = ConfigurationItem(
                    fqn: FQN(namespace: define.namespace!, key: define.key!),
                    type: type,
                    value: define.value!,
                    source: url
                )
                
                items.append(item)
            } // for
            
            // add bean
            
            beans.append(try beanDeclaration(ConfigurationNamespaceHandlerSource(name: url, items: items)))
        }
    }
}