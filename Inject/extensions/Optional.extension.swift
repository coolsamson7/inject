//
//  Optional.extension.swift
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
            case .none:
                return false
            case .some:
                return true
        }
    }

    public func wrappedType() -> Any.Type {
        return Wrapped.self
    }

    public func unwrap() -> Any {
        switch self {
            case .none:
                fatalError("cannot unwrap empty optional")

            case .some(let unwrapped):
                return unwrapped
        }
    }
}
