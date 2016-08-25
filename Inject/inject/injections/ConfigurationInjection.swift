//
//  ConfigurationInjection.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// `ConfigurationValueInjection`  computes values for configuration value injections based on the class `InjectConfigurationValue`
public class ConfigurationValueInjection : Injection {
    // MARK: instance data
    
    var configurationManager : ConfigurationManager
    
    // MARK: init

    public init(configurationManager : ConfigurationManager) {
        self.configurationManager = configurationManager
        
        super.init(clazz: InjectConfigurationValue.self)
    }
    
    // implement
    
    override func computeValue(inject : Inject, property: BeanDescriptor.PropertyDescriptor, environment: Environment) throws -> Any {
        if let injectConfigurationValue = inject as? InjectConfigurationValue {
            return try configurationManager.getValue(property.getPropertyType(), namespace: injectConfigurationValue.namespace, key: injectConfigurationValue.key, defaultValue: injectConfigurationValue.defaultValue)
        } // if
        
        fatalError("should not happen")
    }
}

/// A injection kind for configuration values
public class InjectConfigurationValue : Inject {
    // MARK: instance data
    
    var namespace : String
    var key        : String
    var defaultValue : Any?
    
    // MARK: init

    public init(namespace : String = "", key : String, defaultValue : Any? = nil) {
        self.namespace = namespace
        self.key = key
        self.defaultValue = defaultValue
    }
}