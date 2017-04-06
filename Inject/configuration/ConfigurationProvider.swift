//
//  ConfigurationProvider.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `ConfigurationProvider` is able to retrieve configuration values
protocol ConfigurationProvider {
    func getConfigurationItem(_ namespace : String, key : String) -> ConfigurationItem?

    func hasValue(_ namespace : String, key : String,  scope : Scope?) -> Bool

    func getValue(_ type : Any.Type, namespace : String, key : String, defaultValue: Any?, scope : Scope?) throws -> Any
    
    func addListener(_ namespace : String, key : String,  listener : ConfigurationListener , expectedType : Any.Type, scope : Scope) -> Void
}
