//
//  PlistConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A configuration source based on plists
public class PlistConfigurationSource : AbstractConfigurationSource {
    // MARK: class func

    class func bundle(forClass: AnyClass? = nil) -> NSBundle {
        var bundle = NSBundle.mainBundle()

        if forClass != nil {
            bundle = NSBundle(forClass: forClass!)
        }

        return bundle
    }

    // MARK: init

    override public init() {
        super.init()
    }

    public init(name : String, forClass: AnyClass? = nil) {
        super.init(url: PlistConfigurationSource.bundle(forClass).pathForResource(name, ofType: "plist")!, mutable: false, canOverrule: true)

    }

    // MARK: override AbstractConfigurationSource

    override public func load(configurationManager : ConfigurationManager) throws -> Void {
        let dict = NSDictionary(contentsOfFile: url) as! [String: AnyObject]

        // noop

        for (key, value) in dict {
            try configurationManager.configurationAdded(ConfigurationItem(fqn: FQN.fromString(key), type: value.dynamicType, value: value, source: url, scope: Scope.WILDCARD, dynamic: false), source: self)
        }
    }
}
