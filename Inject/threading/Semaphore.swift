//
// Created by Andreas Ernst on 19.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// Wrapper for `dispatch_semaphore_t`
open class Semaphore {
    // MARK: instance data

    let semaphore: DispatchSemaphore

    // init

    /// Create a new `Semaphore` given an initial count
    /// - Parameter value: the initial value or 0
    public init(value: Int = 0) {
        semaphore = DispatchSemaphore(value: value)
    }

    /// Blocks the thread until the semaphore is free and returns true
    /// or until the timeout passes and returns false

    open func wait(_ nanosecondTimeout: Int64) -> Bool {
        return semaphore.wait(timeout: DispatchTime.now() + Double(nanosecondTimeout) / Double(NSEC_PER_SEC)) == DispatchTimeoutResult.success
    }

    /// Blocks the thread until the semaphore is free

    open func wait() {
        semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    /// Alerts the semaphore that it is no longer being held by the current thread
    /// and returns a boolean indicating whether another thread was woken

    open func signal() -> Bool {
        return semaphore.signal() != 0
    }
}
