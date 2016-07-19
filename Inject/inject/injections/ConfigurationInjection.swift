//
//  ConfigurationInjection.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
public class ConfigurationValueInjection : Injection {
    // instance data
    
    var configurationManager : ConfigurationManager?
    
    // init
    
    init(configurationManager : ConfigurationManager) {
        self.configurationManager = configurationManager
        
        super.init(clazz: InjectConfigurationValue.self)
    }
    
    // implement
    
    override func computeValue(inject : Inject, property: BeanDescriptor.PropertyDescriptor, context : ApplicationContext) throws -> Any {
        if let injectConfigurationValue = inject as? InjectConfigurationValue {
            return try configurationManager!.getValue(property.getPropertyType(), namespace: injectConfigurationValue.namespace, key: injectConfigurationValue.key, defaultValue: injectConfigurationValue.defaultValue)
        } // if
        
        fatalError("should not happen")
    }
}

@objc(InjectConfigurationValue)
public class InjectConfigurationValue : Inject {
    // instance data
    
    var namespace : String
    var key        : String
    var defaultValue : AnyObject?
    
    // init
    
    init(namespace : String, key : String, defaultValue : AnyObject) {
        self.namespace = namespace
        self.key = key
        self.defaultValue = defaultValue
    }
}