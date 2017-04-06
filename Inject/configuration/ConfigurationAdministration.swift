//
//  ConfigurationAdministration.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// the administrative protocol
public protocol ConfigurationAdministration {
    func addSource(_ source : ConfigurationSource) throws -> Void
    
    func configurationAdded(_ item: ConfigurationItem , source : ConfigurationSource) throws -> Void
    
    func configurationChanged(_ item : ConfigurationItem) throws -> Void
}
