//
//  Bean.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// This protocol covers life cycle callbacks that will be called on constructed instances

public protocol Bean {
    /// called after the instance is constructed including all injections
    func postConstruct() throws -> Void ;
}