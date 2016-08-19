//
//  Injection.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// `Injection`s are classes that compute requested injected objects based on different tye of injections.
/// This is a base class
public class Injection : NSObject, Bean, BeanDescriptorInitializer {
    // MARK: instance data
    
    var injector : Injector?
    var clazz : AnyClass;
    
    // init
    
    override init() {
        clazz = Injection.self
    }
    
    init(clazz : AnyClass) {
        self.clazz = clazz
    }
    
    // MARK: public
    
    func computeValue(inject : Inject, property: BeanDescriptor.PropertyDescriptor, environment: Environment) throws -> Any {
        return self// implement!
    }
    
    // MARK: implement ClassInitializer
    
    public func initializeBeanDescriptor(beanDescriptor : BeanDescriptor) {
        beanDescriptor["injector"].autowire()
    }
    
    // MARK: implement Bean
    
    public func postConstruct() -> Void {
        injector!.register(self)
    }
}