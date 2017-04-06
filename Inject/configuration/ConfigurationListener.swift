//
//  ConfigurationListener.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `ConfigurationListener` will be informaed about configuration value changes
public protocol ConfigurationListener {
    func onItemChanged(_ namespace : String, key : String, value : Any) -> Void
}
