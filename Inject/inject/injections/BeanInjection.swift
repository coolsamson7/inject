//
//  BeanInjection.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
/// `BeanInjection` executes injections for beans based on the class `InjectBean`
public class BeanInjection : Injection {
    // MARK: init
    
    override public init() {
        super.init(clazz: InjectBean.self)
    }
    
    // MARK:  implement Injection
    
    override func computeValue(inject : Inject, property: BeanDescriptor.PropertyDescriptor, environment: Environment) throws -> Any {
        if let beanInject = inject as? InjectBean {
            if beanInject.id != nil {
                return try environment.getBean(AnyObject.self, byId: beanInject.id!);
            }
            else {
                return try environment.getBean(property.getPropertyType())
            }
        } // if
        
        fatalError("should not happen")
    }
}
