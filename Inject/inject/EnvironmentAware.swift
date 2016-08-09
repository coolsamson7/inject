//
//  EnvironmentAware.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// this protocol gives a bean the chance to get informed about the ´Environment´ that constructed it
protocol EnvironmentAware {
    /// the setter will be called by the environment

    var environment: Environment? { get set }
}