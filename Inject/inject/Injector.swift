//
//  Injector.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
@objc(Injector)
public class Injector : NSObject {
    // local classes
    
    class ClassInjections {
        // instance data
        
        var injections : [(inject: Inject, property: BeanDescriptor.PropertyDescriptor, injection: Injection)] = []
        
        // init
        
        init(injector : Injector, bean : BeanDescriptor) {
            analyze(injector, bean: bean);
        }
        
        func inject(target : AnyObject, context: ApplicationContext) throws -> Void {
            for (inject, property, injection) in injections {
                let value = try injection.computeValue(inject, property: property, context: context)
                
                if (Tracer.ENABLED) {
                    Tracer.trace("loader", level: .HIGH, message: "inject \(value) in property \(target.dynamicType).\(property.getName())")
                }
                
                try property.set(target, value: value as! AnyObject)
            }
        }
        
        func analyze(injector : Injector, bean : BeanDescriptor) -> Void {
            for property in bean.allProperties {
                if let inject = property.inject {
                    let injection = injector.injections[inject.dynamicType]!
                    
                    injections.append((inject: inject, property: property, injection: injection))
                }
            }
        }
    }
    
    // instance data
    
    var injections = IdentityMap<AnyObject,Injection>()
    var cachedInjections = IdentityMap<AnyObject,ClassInjections>()
    
    // internal
    
    // public
    
    func register(injections : Injection...) {
        for injection in injections {
            self.injections[injection.clazz] = injection
        }
    }
    
    func inject(target : AnyObject, context: ApplicationContext) throws -> Void  {
        let bean = BeanDescriptor.forClass(target.dynamicType)
        
        if let classInjections = cachedInjections[bean.clazz] {
            try classInjections.inject(target, context: context);
        }
        else {
            let classInjections = ClassInjections(injector: self, bean:bean)
            cachedInjections[bean.clazz] = classInjections
            
            try classInjections.inject(target, context: context)
        }
        
    }
}