//
//  String.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

protocol OptionalType {
    func wrappedType() -> Any.Type
}

extension Optional : OptionalType {
    public func isSome() -> Bool {
        switch self {
            case .None:
                return false
            case .Some:
                return true
        }
    }

    public func wrappedType() -> Any.Type {
        return Wrapped.self
    }

    public func unwrap() -> Any {
        switch self {
            case .None:
                fatalError("cannot unwrap empty optional")

            case .Some(let unwrapped):
                return unwrapped
        }
    }
}
