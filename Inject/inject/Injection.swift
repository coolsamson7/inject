//
//  Injection.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
public class Injection : NSObject, Bean, ClassInitializer {
    // instance data
    
    var injector : Injector?
    var clazz : AnyClass;
    
    // init
    
    override init() {
        clazz = Injection.self
        
        super.init()
    }
    
    init(clazz : AnyClass) {
        self.clazz = clazz
    }
    
    // public
    
    func computeValue(inject : Inject, property: BeanDescriptor.PropertyDescriptor, context : ApplicationContext) throws -> AnyObject {
        return self// implement!
    }
    
    // class Initializer
    
    func initializeClass() {
        try! BeanDescriptor.forClass(Injection.self).getProperty("injector").autowire()
    }
    
    // Bean
    
    func postConstruct() -> Void {
        injector!.register(self)
    }
}