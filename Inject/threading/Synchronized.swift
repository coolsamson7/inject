//
// Created by Andreas Ernst on 19.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation


/// Protects `action` using an Objective-C as a token for a mutex lock; similar to Objective-C @synchronized directive.
///
///     synchronized(self) {
///        // Critical section
///     }
/// - Parameters:
///    - lockToken: An Objective-C object to protect the critical section of code
///    - action: The critical section of code to be protected
/// - Returns: Result of `action()`

public func synchronized<ReturnType>(lockToken: AnyObject, @noescape action: () -> ReturnType) -> ReturnType {
    return synchronized(lockToken, action: action())
}

/// Protects `action` using an Objective-C as a token for a mutex lock; similar to Objective-C @synchronized directive.
///
///     return synchronized(self, action: atomicProperty)
/// - Parameters:
///    - lockToken: An Objective-C object to protect the critical section of code
///    - action: The critical section of code to be protected
/// - Returns: Result of `action()`

public func synchronized<ReturnType>(lockToken: AnyObject, @autoclosure action: () -> ReturnType) -> ReturnType {
    defer { objc_sync_exit(lockToken) }

    objc_sync_enter(lockToken)

    return action()
}