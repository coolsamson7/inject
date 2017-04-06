//
//  PlistConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A configuration source based on plists
open class PlistConfigurationSource : AbstractConfigurationSource {
    // MARK: class func

    class func bundle(_ forClass: AnyClass? = nil) -> Bundle {
        var bundle = Bundle.main

        if forClass != nil {
            bundle = Bundle(for: forClass!)
        }

        return bundle
    }

    // MARK: init

    override public init() {
        super.init()
    }

    public init(name : String, forClass: AnyClass? = nil) {
        super.init(url: PlistConfigurationSource.bundle(forClass).path(forResource: name, ofType: "plist")!, mutable: false, canOverrule: true)

    }

    // MARK: override AbstractConfigurationSource

    override open func load(_ configurationManager : ConfigurationManager) throws -> Void {
        let dict = NSDictionary(contentsOfFile: url) as! [String: AnyObject]

        // noop

        for (key, value) in dict {
            try configurationManager.configurationAdded(ConfigurationItem(fqn: FQN.fromString(key), type: type(of: value), value: value, source: url, scope: Scope.WILDCARD, dynamic: false), source: self)
        }
    }
}
