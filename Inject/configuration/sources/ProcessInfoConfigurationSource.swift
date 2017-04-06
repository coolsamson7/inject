//
//  ProcessInfoConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A configuration source based on the process info
open class ProcessInfoConfigurationSource : AbstractConfigurationSource {
    // init

    override public init() {
        super.init(url: "process info", mutable: false, canOverrule: true)
    }

    public init(name : String) {
        super.init(url: name, mutable: false, canOverrule: true)
    }

    // override

    override open func load(_ configurationManager : ConfigurationManager) throws -> Void {
        let dict = ProcessInfo.processInfo.environment

        // noop

        for (key, value) in dict {
            try configurationManager.configurationAdded(ConfigurationItem(fqn: FQN.fromString(key), type: String.self, value: value, source: url, scope: Scope.WILDCARD, dynamic: false), source: self)
        }
    }
}
