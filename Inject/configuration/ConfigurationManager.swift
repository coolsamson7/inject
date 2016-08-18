//
//  ConfigurationManager.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// central class that collects `ConfigurationSource`'s and is able to retieve configuration values.
public class ConfigurationManager : NSObject, ConfigurationAdministration, ConfigurationProvider {
    // local class
    
    class ScopeAndName : Hashable {
        // MARK: instance data
        
        var scope : Scope
        var fqn : FQN
        
        // init
        
        init(scope : Scope, fqn : FQN) {
            self.scope = scope
            self.fqn = fqn
        }
        
        // Hashable
        
        var hashValue: Int {
            get {
                return scope.hashValue &+ fqn.hashValue
            }
        }
    }
    
    class ConfigurationListenerData : Equatable {
        // MARK: instance data
        
        var scope : Scope
        var fqn : FQN
        var configurationListener : ConfigurationListener
        var type: Any.Type;
        
        // init
        
        init( scope : Scope, fqn : FQN,  configurationListener : ConfigurationListener, expectedType : Any.Type) {
            self.scope = scope;
            self.fqn = fqn;
            self.configurationListener = configurationListener;
            self.type = expectedType;
        }
    }
    
    // static data
    
    static var NOT_FOUND : ConfigurationItem = ConfigurationItem(fqn: FQN(namespace: "", key: ""), type: Any.self, value: "", source: "", scope : Scope.WILDCARD)
    
    // MARK: instance data
    
    var scope : Scope
    var sources  = [ConfigurationSource]()
    
    var items = [ScopeAndName : ConfigurationItem]();
    var cachedItems = [ScopeAndName : ConfigurationItem]();
    var listeners = [FQN: ArrayOf<ConfigurationListenerData>]();
    
    // init
    
    override init() {
        scope = Scope.WILDCARD
        super.init()
    }
    
    init(scope : Scope, sources : ConfigurationSource... ) throws {
        self.scope = scope
        
        super.init()
        
        for source in sources {
            try addSource(source)
        }
    }
    
    // private
    
    private func getItem(scope : Scope, fqn : FQN) -> ConfigurationItem? {
        return items[ScopeAndName(scope : scope, fqn : fqn)]
    }
    
    private func resolveEffectiveConfigurationItem(scope : Scope, fqn : FQN,  scopeAndName : ScopeAndName) -> ConfigurationItem? {
        var resultItem = items[scopeAndName];
        if resultItem == nil  {
            let parentScope = scope.getParentScope();
            if parentScope != nil {
                resultItem = getEffectiveConfigurationItem(parentScope!, fqn : fqn);
            }
        } // if
        
        // cache result
        
        cachedItems[scopeAndName] = resultItem == nil ? ConfigurationManager.NOT_FOUND : resultItem;
        
        return resultItem;
    }
    
    private func getEffectiveConfigurationItem(scope : Scope, fqn : FQN) -> ConfigurationItem? {
        let scopeAndName = ScopeAndName(scope: scope, fqn: fqn);
        
        var resultItem = cachedItems[scopeAndName];
        
        if resultItem == nil {
            resultItem = resolveEffectiveConfigurationItem(scope, fqn: fqn, scopeAndName: scopeAndName);
        }
        
        return resultItem === ConfigurationManager.NOT_FOUND ? nil : resultItem;
    }
    
    func maybeConvert(type : Any.Type, value : Any) throws -> Any {
        var valueType : Any.Type = value.dynamicType
        
        if type != valueType {
            // strange things happen with strings that occur in different layouts... NSContiguousString, NSTaggedPointerString, etc.
            
            if value is String {
                valueType = String.self
            }
            else if value is Int {
                valueType = Int.self
            }
            else if value is Double {
                valueType = Double.self
            }
            else if value is Float {
                valueType = Float.self
            }
            
            // recheck
            
            if type != valueType {
                // find possible conversion
                
                return try StandardConversionFactory.instance.getConversion(valueType, targetType: type)(object: value)
            }
        }
        
        return value
    }

    func report() -> String {
        let builder = StringBuilder()

        builder.append("### Configuration Report\n\n")

        var descriptions = [String: ArrayOf<FQN>]();
        for (_, item) in self.items {
            var itemsFromResource = descriptions[item.source];

            if itemsFromResource == nil {
                itemsFromResource = ArrayOf<FQN>();
                descriptions[item.source] = itemsFromResource;
            }

            if !itemsFromResource!.contains(item.fqn) {
                itemsFromResource!.append(item.fqn);
            } // if
        } // for


        if !descriptions.isEmpty {
            for (source, items) in descriptions {
                builder.append("\n### Source \"\(source)\"\n")

                for fqn in items { // sorting
                    let item = getEffectiveConfigurationItem(self.scope, fqn: fqn)
                    if item != nil {
                        builder.append(fqn).append("=\(item!.value)\n")
                    }
                }

                builder.append("\n");
            }
        }
        else {
            builder.append("none");
        }

        return builder.toString()
    }

    // ConfigurationAdministration
    
    public func addSource(source : ConfigurationSource) throws -> Void {
        sources.append(source)
        
        try source.load(self)
    }

    public func configurationAdded(item: ConfigurationItem , source : ConfigurationSource) throws -> Void {
        let existingItem =  getItem(item.scope, fqn: item.fqn)
        
        if existingItem != nil {
            if existingItem!.scope == item.scope && !source.canOverrule {
                throw ConfigurationErrors.Exception(message: "attempt to override item \(existingItem!.fqn) from resource \(existingItem!.source) with resource \(source.url)");
            }
        }
        
        try configurationChanged(item);
    }

    public func configurationChanged(item: ConfigurationItem) throws -> Void {
        items[ScopeAndName(scope : item.scope, fqn : item.fqn)] = item
        
        let listenerData = listeners[item.fqn]
        if listenerData != nil {
            for configurationListenerData in listenerData! {
                configurationListenerData.configurationListener.onItemChanged(item.fqn.namespace, key: item.fqn.key, value: try maybeConvert(configurationListenerData.type, value: item.value));
            }
        }
        
        cachedItems.removeAll()
    }
    
    // ConfigurationProvider
    
    public func addListener(namespace : String = "", key : String,  listener : ConfigurationListener , expectedType : Any.Type, scope : Scope = Scope.WILDCARD) -> Void {
        let fqn = FQN(namespace: namespace, key: key)
        
        if listeners[fqn] == nil {
            listeners[fqn] = ArrayOf<ConfigurationListenerData>(values: ConfigurationListenerData(scope: scope, fqn: fqn, configurationListener: listener, expectedType: expectedType))
        }
        else {
            listeners[fqn]!.append(ConfigurationListenerData(scope: scope, fqn: fqn, configurationListener: listener, expectedType: expectedType))
        }
    }

    public func getConfigurationItem(namespace : String = "", key : String) -> ConfigurationItem? {
        return items[ScopeAndName(scope : scope, fqn: FQN(namespace: namespace, key: key))]
    }

    public func hasValue(namespace : String = "", key : String, scope : Scope? = nil) -> Bool {
        return getEffectiveConfigurationItem(scope != nil ? scope! : self.scope, fqn: FQN(namespace: namespace, key: key)) != nil
    }
    
    public func getValue(type : Any.Type, namespace : String = "", key : String, defaultValue: Any? = nil, scope : Scope? = nil) throws -> Any {
        let resultItem = getEffectiveConfigurationItem(scope != nil ? scope! : self.scope, fqn: FQN(namespace: namespace, key: key));
        
        if resultItem == nil {
            if defaultValue != nil {
                if (Tracer.ENABLED) {
                    Tracer.trace("configuration", level: .HIGH, message: "\(namespace).\(key) = default value \(defaultValue)")
                }
                
                return try maybeConvert(type, value: defaultValue!)
            }
            else {
                throw ConfigurationErrors.Exception(message: "neither configuration value\(namespace):\(key) nor default found");//return defaultValue
            }
        }
        else {
            if (Tracer.ENABLED) {
                Tracer.trace("configuration", level: .HIGH, message: "\(namespace).\(key) = \(resultItem!.value)")
            }
            
            if resultItem!.dynamic {
                throw ConfigurationErrors.Exception(message: "the dynamic configuration value\(namespace):\(key) cannot be fetched via getValue");
            }
            
            return try maybeConvert(type, value: resultItem!.value)
        }
    }

    public func getValue<T>(type : T.Type, namespace : String = "", key : String, defaultValue: T? = nil, scope : Scope? = nil) throws -> T {
        let resultItem = getEffectiveConfigurationItem(scope != nil ? scope! : self.scope, fqn: FQN(namespace: namespace, key: key));
        
        if resultItem == nil {
            if defaultValue != nil {
                if (Tracer.ENABLED) {
                    Tracer.trace("configuration", level: .HIGH, message: "\(namespace).\(key) = default value \(defaultValue)")
                }
                
                return try maybeConvert(type, value: defaultValue!) as! T
            }
            else {
                throw ConfigurationErrors.Exception(message: "neither configuration value\(namespace):\(key) nor default found");
            }
        }
        else {
            if (Tracer.ENABLED) {
                Tracer.trace("configuration", level: .HIGH, message: "\(namespace).\(key) = \(resultItem!.value)")
            }
            
            if resultItem!.dynamic {
                throw ConfigurationErrors.Exception(message: "the dynamic configuration value\(namespace):\(key) cannot be fetched via getValue");
            }
            
            return try maybeConvert(type, value: resultItem!.value) as! T
        }
    }
}

func ==(lhs: ConfigurationManager.ScopeAndName, rhs: ConfigurationManager.ScopeAndName) -> Bool {
    return lhs.scope == rhs.scope && lhs.fqn == rhs.fqn
}

func ==(lhs: ConfigurationManager.ConfigurationListenerData, rhs: ConfigurationManager.ConfigurationListenerData) -> Bool {
    return lhs === rhs
}