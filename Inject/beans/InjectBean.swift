
//
//  InjectBean.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

/// `InjectBean` is a injection kind for beans
open class InjectBean : Inject {
    // MARK: instance data
    
    var id : String?
    
    // MARK: init

    /// Create a new `InjectBean`
    /// - Parameter id: an optional id
    public init(id : String? = nil) {
        self.id = id
    }
}
