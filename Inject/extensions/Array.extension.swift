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

    func factory() -> () -> Any

    mutating func _append(_ value : Any) -> Void
}

extension Array : ArrayType {
    // ArrayType

    func elementType() -> Any.Type {
        return Element.self
    }

    func factory() -> () -> Any {
        return {Array<Element>()}
    }

    mutating func _append(_ value : Any) -> Void {
        self.append(value as! Element)
    }
}

extension Array where Element : Any {
    func newInstance() -> Array {
        return Array<Element>()
    }
}
