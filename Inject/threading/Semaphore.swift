//
// Created by Andreas Ernst on 19.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class Semaphore {
    // instance data

    let semaphore: dispatch_semaphore_t

    // init

    init(value: Int = 0) {
        semaphore = dispatch_semaphore_create(value)
    }

    /// Blocks the thread until the semaphore is free and returns true
    /// or until the timeout passes and returns false

    public func wait(nanosecondTimeout: Int64) -> Bool {
        return dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, nanosecondTimeout)) != 0
    }

    /// Blocks the thread until the semaphore is free

    public func wait() {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }

    /// Alerts the semaphore that it is no longer being held by the current thread
    /// and returns a boolean indicating whether another thread was woken

    public func signal() -> Bool {
        return dispatch_semaphore_signal(semaphore) != 0
    }
}
