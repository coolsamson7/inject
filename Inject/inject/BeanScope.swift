//
//  BeanScope.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

protocol BeanScope {
    var name : String {
        get
    }
    
    func prepare(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws
    
    func get(bean : ApplicationContext.BeanDeclaration, factory : BeanFactory) throws -> AnyObject
    
    func finish()
}