//
//  PlistConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//


public class PlistConfigurationSource : AbstractConfigurationSource {
    // MARK: instance data

    var name : String? {
        didSet {
            _url = NSBundle.mainBundle().pathForResource(name, ofType: "plist")!
        }
    }

    // init

    override init() {
        super.init()
    }

    init(name : String) {
        super.init(url: name /*NSBundle.mainBundle().pathForResource(name, ofType: "plist")!*/, mutable: false, canOverrule: true)
    }

    // override

    override public func load(configurationManager : ConfigurationManager) throws -> Void {
        let dict = NSDictionary(contentsOfFile: url) as! [String: AnyObject]

        // noop

        for (key, value) in dict {
            try configurationManager.configurationAdded(ConfigurationItem(fqn: FQN.fromString(key), type: value.dynamicType, value: value, source: url, scope: Scope.WILDCARD, dynamic: false), source: self)
        }
    }
}
