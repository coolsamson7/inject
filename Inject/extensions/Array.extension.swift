//
//  Array.extension.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

protocol ArrayType {
    func elementType() -> Any.Type
}

extension Array : ArrayType {
    // ArrayType

    func elementType() -> Any.Type {
        return Element.self
    }
}