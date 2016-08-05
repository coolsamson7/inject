//
//  ProcessInfoSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class ProcessInfoConfigurationSource : AbstractConfigurationSource {
    // init

    override init() {
        super.init(url: "process info", mutable: false, canOverrule: true)
    }

    init(name : String) {
        super.init(url: name, mutable: false, canOverrule: true)
    }

    // override

    override func load(configurationManager : ConfigurationManager) throws -> Void {
        let dict = NSProcessInfo.processInfo().environment

        // noop

        for (key, value) in dict {
            try configurationManager.configurationAdded(ConfigurationItem(fqn: FQN.fromString(key), type: String.self, value: value, source: url, scope: Scope.WILDCARD, dynamic: false), source: self)
        }
    }
}