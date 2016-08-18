//
//  OriginAware.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

// classes implementing this protocol will be informed about line and column data of the corresponding xml element
public protocol OriginAware {
    /// line and column number
    var origin : Origin? { get set }
}