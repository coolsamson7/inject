//
//  Injection.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// `Injection`s are classes that compute objects that will be injected in an object based on a specific `Inject` class.
open class Injection : NSObject, Bean, BeanDescriptorInitializer {
    // MARK: instance data
    
    var injector : Injector?
    var clazz : AnyClass
    
    // init

    override init() {
        self.clazz = type(of: self) // anything...

        super.init()
    }

    init(clazz : AnyClass) {
        self.clazz = clazz
    }
    
    // MARK: public
    
    func computeValue(_ inject : Inject, property: BeanDescriptor.PropertyDescriptor, environment: Environment) throws -> Any {
        return self // implement!
    }
    
    // MARK: implement BeanDescriptorInitializer
    
    open func initializeBeanDescriptor(_ beanDescriptor : BeanDescriptor) {
        beanDescriptor["injector"].autowire()
    }
    
    // MARK: implement Bean
    
    open func postConstruct() -> Void {
        injector!.register(self)
    }
}
