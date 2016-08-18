//
//  ConfigurationItem.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `ConfigurationItem` stores information about a configuration value ( name, source, type, e.g )
public class ConfigurationItem {
    // MARK: instance data
    
    var fqn : FQN
    var type : Any.Type
    var value : Any
    var source : String
    var scope : Scope
    var dynamic = false
    
    // init
    
    init(fqn : FQN, type : Any.Type, value : Any, source : String, scope : Scope = Scope.WILDCARD, dynamic : Bool = false) {
        self.fqn     = fqn
        self.type    = type
        self.value   = value
        self.source  = source
        self.scope   = scope
        self.dynamic = dynamic
    }
}