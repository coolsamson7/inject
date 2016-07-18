//
//  ConfigurationProvider.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

protocol ConfigurationProvider {
    func getConfigurationItem(namespace : String, key : String) -> ConfigurationItem?
    
    func getValue(type : Any.Type, namespace : String, key : String, defaultValue: AnyObject?, scope : Scope?) throws -> AnyObject?
    
    func addListener(namespace : String, key : String,  listener : ConfigurationListener , expectedType : AnyClass, scope : Scope) -> Void
}