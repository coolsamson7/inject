//
//  Ancestor.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

// classes implementing this protocol will be informaed about constructed child nodes
public protocol Ancestor {
    /// informs this instance about a new child
    /// - Parameter chidl: any child
    func addChild(_ child : AnyObject) -> Void
}
