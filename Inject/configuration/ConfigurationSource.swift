//
//  ConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `ConfigurationSource` is a source for configuration values

public protocol ConfigurationSource {
    func load(_ configurationManager : ConfigurationManager) throws -> Void

    func startListening(_ configurationManager : ConfigurationManager, seconds : Int) -> Void
    
    var url : String { get }

    var mutable : Bool { get }

    var canOverrule: Bool { get }
}
