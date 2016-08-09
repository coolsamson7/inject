//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class Mutex : Lock {
    // MARK: instance data

    internal var mutex = pthread_mutex_t()

    // init

    public init(){
        pthread_mutex_init(&mutex, nil)
    }

    deinit{
        pthread_mutex_destroy(&mutex)
    }

    // Lock

    public func lock(){
        pthread_mutex_lock(&mutex)
    }

    public func unlock(){
        pthread_mutex_unlock(&mutex)
    }

    func synchronized(closure : ()->()) {
        lock()

        defer { unlock() }

        closure()
    }
}
