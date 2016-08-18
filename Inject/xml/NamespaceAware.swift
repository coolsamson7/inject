//
//  NamespaceAware.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

// classes implementing this protocol will be informed about xml namespaces
public protocol NamespaceAware {
    /// the namespace
    var namespace : String? { get set }
}