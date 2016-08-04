//
//  ContextAware.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

protocol EnvironmentAware {
    var environment: Environment? { get set }
}