//
//  BeanInjection.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
public class BeanInjection : Injection {
    // init
    
    override init() {
        super.init(clazz: InjectBean.self)
    }
    
    // implement
    
    override func computeValue(inject : Inject, property: BeanDescriptor.PropertyDescriptor, context : ApplicationContext) throws -> Any {
        if let beanInject = inject as? InjectBean {
            if beanInject.id != nil {
                return try context.getBean(AnyObject.self, byId: beanInject.id!);
            }
            else {
                let clazz : AnyClass = property.getPropertyType() as! AnyClass // = AnyObject.type

                return try context.getBean(clazz)
            }
        } // if
        
        fatalError("should not happen")
    }
}
