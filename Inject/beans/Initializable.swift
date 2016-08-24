
//
//  Initializable.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// All classes that conform to this protocol can be constructed on a generic basis....oh boy
public protocol Initializable : class {
    init()
}