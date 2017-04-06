//
//  AbstractConfigurationSource.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// Base class for a `ConfigurationSource`
open class AbstractConfigurationSource : NSObject, ConfigurationSource, Bean, BeanDescriptorInitializer {
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
    
    open func initializeBeanDescriptor(_ beanDescriptor : BeanDescriptor) {
        beanDescriptor["configurationManager"].autowire()
    }
    
    // MARK: implement Bean
    
    open func postConstruct() throws -> Void {
        try configurationManager!.addSource(self)
    }
    
    // MARK: implement ConfigurationSource
    
    open func load(_ configurationManager : ConfigurationManager) throws -> Void {
        // noop
    }

    open func startListening(_ configurationManager : ConfigurationManager, seconds : Int) -> Void {
        // noop
    }

    open var url : String {
        get {
            return _url
        }
    }

    open var mutable : Bool {
        get {
            return _mutable
        }
    }

    open var canOverrule : Bool {
        get {
            return _canOverrule
        }
    }
}
