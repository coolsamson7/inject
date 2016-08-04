//
//  BeanScope.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public protocol BeanScope {
    var name : String {
        get
    }
    
    func prepare(bean : Environment.BeanDeclaration, factory : BeanFactory) throws
    
    func get(bean : Environment.BeanDeclaration, factory : BeanFactory) throws -> AnyObject
    
    func finish()
}