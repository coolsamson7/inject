//
//  AbstractConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// Base class for a `ConfigurationSource`
public class AbstractConfigurationSource : NSObject, ConfigurationSource, Bean, BeanDescriptorInitializer {
    // MARK: instance data
    
    var _url : String = ""
    var _mutable = false
    var _canOverrule = false
    var configurationManager : ConfigurationManager? = nil // injected
    
    // MARK: init
    
    override public init() {
    }

    public init(configurationManager : ConfigurationManager, url : String, mutable : Bool = false, canOverrule : Bool = false) {
        self.configurationManager = configurationManager
        self._url = url
        self._mutable = mutable
        self._canOverrule = canOverrule
    }

    public init(url : String, mutable : Bool, canOverrule : Bool) {
        self._url = url
        self._mutable = mutable
        self._canOverrule = canOverrule
    }
    
    // MARK: implement BeanDescriptorInitializer
    
    public func initializeBeanDescriptor(beanDescriptor : BeanDescriptor) {
        beanDescriptor["configurationManager"].autowire()
    }
    
    // MARK: implement Bean
    
    public func postConstruct() throws -> Void {
        try configurationManager!.addSource(self)
    }
    
    // MARK: implement ConfigurationSource
    
    public func load(configurationManager : ConfigurationManager) throws -> Void {
        // noop
    }

    public func startListening(configurationManager : ConfigurationManager, seconds : Int) -> Void {
        // noop
    }

    public var url : String {
        get {
            return _url
        }
    }

    public var mutable : Bool {
        get {
            return _mutable
        }
    }

    public var canOverrule : Bool {
        get {
            return _canOverrule
        }
    }
}