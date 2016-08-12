//
//  ConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public protocol ConfigurationSource {
    func load(configurationManager : ConfigurationManager) throws -> Void
    func startListening(configurationManager : ConfigurationManager, seconds : Int) -> Void
    
    var url : String { get }
    var mutable : Bool { get }
    var canOverrule: Bool { get }
}