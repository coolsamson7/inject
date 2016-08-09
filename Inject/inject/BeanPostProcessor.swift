//
//  BeanPostProcessor.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A ´BeanPostProcessor´ is responsible to take a constructed object and to modify it or completely replace it with another matching object
protocol BeanPostProcessor {
    // post process the given object
    // - Paramater bean: the bean
    // - Returns: the possibly modified object
    // - Throws any error
    func process(bean : AnyObject) throws -> AnyObject
}