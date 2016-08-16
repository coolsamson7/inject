//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// A `FactoryBean` is a bean whose purpose is to create other beans
protocol FactoryBean {
    /// create the corresponding bean
    /// - Returns: the bean instance
    /// - Throws: any possible error
    func create() throws -> AnyObject
}
