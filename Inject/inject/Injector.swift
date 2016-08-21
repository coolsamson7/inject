//
//  Injector.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// `Injector` is the object that will execute injections based on registered injectors
public class Injector {
    // MARK: local classes
    
    class ClassInjections {
        // MARK: instance data
        
        var injections : [(inject: Inject, property: BeanDescriptor.PropertyDescriptor, injection: Injection)] = []
        
        // MARK: init
        
        init(injector : Injector, bean : BeanDescriptor) {
            analyze(injector, bean: bean);
        }
        
        func inject(target : AnyObject, context: Environment) throws -> Void {
            for (inject, property, injection) in injections {
                let value = try injection.computeValue(inject, property: property, environment: context)
                
                if (Tracer.ENABLED) {
                    Tracer.trace("inject", level: .HIGH, message: "inject \(value) in property \(target.dynamicType).\(property.getName())")
                }
                
                try property.set(target, value: value)
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
    
    // MARK: instance data
    
    var injections = IdentityMap<AnyObject,Injection>()
    var cachedInjections = IdentityMap<AnyObject,ClassInjections>()
    
    // MARK: internal
    
    // MARK: public

    public func register(injections : Injection...) {
        for injection in injections {
            self.injections[injection.clazz] = injection
        }
    }

    public func inject(target : AnyObject, context: Environment) throws -> Void  {
        let bean = try BeanDescriptor.forInstance(target)
        
        if let classInjections = cachedInjections[bean.getClass()] {
            try classInjections.inject(target, context: context)
        }
        else {
            let classInjections = ClassInjections(injector: self, bean:bean)
            cachedInjections[bean.getClass()] = classInjections
            
            try classInjections.inject(target, context: context)
        }
    }
}