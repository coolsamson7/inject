//
// Created by Andreas Ernst on 19.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// A `Future`is a combination of a `Condition` and `Mutex` in order to exchange results between different threads
open class Future<T> {
    // MARK: instance data

    var resolved = false
    var mutex : Mutex
    var condition : Condition
    var result : T? = nil
    var error : Error? = nil

    // init

    public init() {
        mutex = Mutex()
        condition = Condition(mutex: mutex)
    }

    // MARK: public

    /// block the current thread and wait until a result has been set with `setResult()`. After waking up this result is returned. In case of a `setError()` the correspondign error will be thrown
    /// - Returns: the result as set by another thread
    /// - Throws: any error set with `setError()`
    open func getResult() throws -> T {
        mutex.synchronized({
            while !self.resolved  {
                self.condition.wait()
            }
        })

        if error != nil {
            throw error!
        }
        else {
            return result!
        }
    }

    /// Set the result of this future
    /// - Parameter result: the result
    open func setResult(_ result : T) {
        mutex.synchronized({
            self.resolved = true
            self.result = result

            self.condition.signal()
        })
    }

    /// Set the error value of this future
    /// - Parameter error: the error
    open func setError(_ error : Error) {
        mutex.synchronized({
            self.resolved = true
            self.error = error

            self.condition.signal()
        })
    }
}
