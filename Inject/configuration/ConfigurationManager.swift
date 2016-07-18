//
//  ConfigurationManager.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

@objc(ConfigurationManager)
class ConfigurationManager : NSObject, ConfigurationAdministration, ConfigurationProvider {
    // local class
    
    class ScopeAndName : Hashable {
        // instance data
        
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
    
    class ConfigurationListenerData {
        // instance data
        
        var scope : Scope
        var fqn : FQN
        var configurationListener : ConfigurationListener
        var type: AnyClass;
        
        // init
        
        init( scope : Scope, fqn : FQN,  configurationListener : ConfigurationListener, expectedType :AnyClass) {
            self.scope = scope;
            self.fqn = fqn;
            self.configurationListener = configurationListener;
            self.type = expectedType;
        }
    }
    
    // static data
    
    static var NOT_FOUND : ConfigurationItem = ConfigurationItem(fqn: FQN(namespace: "", key: ""), type: AnyObject.self, value: "", source: "", scope : Scope.WILDCARD)
    
    // instance data
    
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
    
    private func  resolveEffectiveConfigurationItem(scope : Scope, fqn : FQN,  scopeAndName : ScopeAndName) -> ConfigurationItem? {
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
    
    func maybeConvert(type : Any.Type, value : AnyObject) throws -> AnyObject? {
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
    
    // ConfigurationAdministration
    
    func addSource(source : ConfigurationSource) throws -> Void {
        sources.append(source)
        
        try source.load(self)
    }
    
    func configurationAdded(item: ConfigurationItem , source : ConfigurationSource) throws -> Void {
        let existingItem =  getItem(item.scope, fqn: item.fqn)
        
        if existingItem != nil {
            if existingItem!.scope == item.scope && !source.canOverrule {
                throw ConfigurationErrors.Exception(message: "attempt to override item \(existingItem!.fqn) from resource \(existingItem!.source) with resource \(source.url)");
            }
        }
        
        try configurationChanged(item);
    }
    
    func configurationChanged(item: ConfigurationItem) throws -> Void {
        items[ScopeAndName(scope : item.scope, fqn : item.fqn)] = item
        
        let listenerData = listeners[item.fqn]
        if listenerData != nil {
            for configurationListenerData in listenerData! {
                configurationListenerData.configurationListener.onItemChanged(item.fqn.namespace, key: item.fqn.key, value: try maybeConvert(configurationListenerData.type, value: item.value)!);
            }
        }
        
        cachedItems.removeAll()
    }
    
    // ConfigurationProvider
    
    func addListener(namespace : String, key : String,  listener : ConfigurationListener , expectedType : AnyClass, scope : Scope = Scope.WILDCARD) -> Void {
        let fqn = FQN(namespace: namespace, key: key)
        
        if listeners[fqn] == nil {
            listeners[fqn] = ArrayOf<ConfigurationListenerData>(values: ConfigurationListenerData(scope: scope, fqn: fqn, configurationListener: listener, expectedType: expectedType))
        }
        else {
            listeners[fqn]!.append(ConfigurationListenerData(scope: scope, fqn: fqn, configurationListener: listener, expectedType: expectedType))
        }
    }
    
    func getConfigurationItem(namespace : String, key : String) -> ConfigurationItem? {
        return items[ScopeAndName(scope : scope, fqn: FQN(namespace: namespace, key: key))]
    }
    
    func getValue(type : Any.Type, namespace : String, key : String, defaultValue: AnyObject? = nil, scope : Scope? = nil) throws -> AnyObject? {
        let resultItem = getEffectiveConfigurationItem(scope != nil ? scope! : self.scope, fqn: FQN(namespace: namespace, key: key));
        
        if resultItem == nil {
            if defaultValue != nil {
                if (Tracer.ENABLED) {
                    Tracer.trace("configuration", level: .HIGH, message: "\(namespace).\(key) = default value \(defaultValue)")
                }
                
                return try maybeConvert(type, value: defaultValue!)
            }
            else {
                return defaultValue
            }
        }
        else {
            if (Tracer.ENABLED) {
                Tracer.trace("configuration", level: .HIGH, message: "\(namespace).\(key) = \(resultItem!.value)")
            }
            
            if resultItem!.dynamic {
                throw ConfigurationErrors.Exception(message: "the dynamic configuration value\(namespace):\(key) cannot be fetched via getValue");
            }
            
            return try maybeConvert(type, value: resultItem!.value);
        }
    }
}

func ==(lhs: ConfigurationManager.ScopeAndName, rhs: ConfigurationManager.ScopeAndName) -> Bool {
    return lhs.scope == rhs.scope && lhs.fqn == rhs.fqn
}