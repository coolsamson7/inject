//
//  Injector.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// `Injector` is the object that will execute injections based on registered injectors
open class Injector {
    // MARK: local classes
    
    class ClassInjections {
        // MARK: instance data
        
        var injections : [(inject: Inject, property: BeanDescriptor.PropertyDescriptor, injection: Injection)] = []
        
        // MARK: init
        
        init(injector : Injector, bean : BeanDescriptor) {
            analyze(injector, bean: bean);
        }
        
        func inject(_ target : AnyObject, context: Environment) throws -> Void {
            for (inject, property, injection) in injections {
                let value = try injection.computeValue(inject, property: property, environment: context)
                
                if (Tracer.ENABLED) {
                    Tracer.trace("inject", level: .high, message: "inject \(value) in property \(type(of: target)).\(property.getName())")
                }
                
                try property.set(target, value: value)
            }
        }
        
        func analyze(_ injector : Injector, bean : BeanDescriptor) -> Void {
            for property in bean.allProperties {
                if let inject = property.inject {
                    if let injection = injector.injections[type(of: inject)] {
                        injections.append((inject: inject, property: property, injection: injection))
                    }
                    else {
                        fatalError("no matching injection for type \(inject)")
                    }
                }
            }
        }
    }
    
    // MARK: instance data
    
    var injections = IdentityMap<AnyObject,Injection>()
    var cachedInjections = IdentityMap<AnyObject,ClassInjections>()
    
    // MARK: internal
    
    // MARK: public

    open func register(_ injections : Injection...) {
        for injection in injections {
            self.injections[injection.clazz] = injection
        }
    }

    open func inject(_ target : AnyObject, context: Environment) throws -> Void  {
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
