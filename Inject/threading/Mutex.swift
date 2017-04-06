//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// Warpper for `pthread_mutex_t`
open class Mutex : Lock {
    // MARK: instance data

    internal var mutex = pthread_mutex_t()

    // init

    /// Create a new `Mutex`
    public init(){
        pthread_mutex_init(&mutex, nil)
    }

    deinit{
        pthread_mutex_destroy(&mutex)
    }

    // Lock

    /// lock
    open func lock() -> Void {
        pthread_mutex_lock(&mutex)
    }

    /// unlock
    open func unlock() -> Void {
        pthread_mutex_unlock(&mutex)
    }

    /// execute the closure function guared by this lock
    /// - Parameter closure: the function
    open func synchronized(_ closure : ()->()) {
        lock()

        defer { unlock() }

        closure()
    }
}
