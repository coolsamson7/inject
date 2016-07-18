//
//  AbstractConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class AbstractConfigurationSource : NSObject, ConfigurationSource, Bean, ClassInitializer  {
    // instance data
    
    var _url : String
    var _mutable = false
    var _canOverrule = false
    var configurationManager : ConfigurationManager? = nil // injected
    
    // init
    
    override init() {
        _url = ""
        
        super.init()
    }
    
    init(url : String, mutable : Bool, canOverrule : Bool) {
        self._url = url
        self._mutable = mutable
        self._canOverrule = canOverrule
    }
    
    // class Initializer
    
    func initializeClass() {
        try! BeanDescriptor.forClass(AbstractConfigurationSource.self).getProperty("configurationManager").autowire()
    }
    
    // Bean
    
    func postConstruct() throws -> Void {
        try configurationManager!.addSource(self)
    }
    
    // ConfigurationSource
    
    func load(configurationManager : ConfigurationManager) throws -> Void {
        // noop
    }
    
    func startListening(configurationManager : ConfigurationManager, seconds : Int) -> Void {
        // noop
    }
    
    var url : String {
        get {
            return _url
        }
    }
    
    var mutable : Bool {
        get {
            return _mutable
        }
    }
    
    var canOverrule : Bool {
        get {
            return _canOverrule
        }
    }
}
// TODO

@objc(ProcessInfoConfigurationSource)
public class ProcessInfoConfigurationSource : AbstractConfigurationSource {
    // init
    
    override init() {
        super.init()
    }
    
    init(name : String) {
        super.init(url: name /*NSBundle.mainBundle().pathForResource(name, ofType: "plist")!*/, mutable: false, canOverrule: true)
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

@objc(PlistConfigurationSource)
public class PlistConfigurationSource : AbstractConfigurationSource {
    // instance data
    
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
    
    override func load(configurationManager : ConfigurationManager) throws -> Void {
        let dict = NSDictionary(contentsOfFile: url) as! [String: AnyObject]
        
        // noop
        
        for (key, value) in dict {
            try configurationManager.configurationAdded(ConfigurationItem(fqn: FQN.fromString(key), type: value.dynamicType, value: value, source: url, scope: Scope.WILDCARD, dynamic: false), source: self)
        }
    }
}

