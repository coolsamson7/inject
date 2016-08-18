//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// A wrapper for `pthread_cond_t`
public class Condition {
    // MARK: instance data

    private var cond = pthread_cond_t()
    private var mutex : Mutex

    // init

    /// create a new `Condition`
    /// - Parameter mutex: the corresponding `Mutex`
    public init(mutex : Mutex){
        self.mutex = mutex

        pthread_cond_init(&cond, nil)
    }

    deinit {
        pthread_cond_destroy(&cond)
    }

    // MARK: public

    /// broadcast
    public func broadcast(){
        pthread_cond_broadcast(&cond)
    }

    /// Signal
    public func signal(){
        pthread_cond_signal(&cond)
    }

    /// wait on this condition
    public func wait(){
        pthread_cond_wait(&cond, &mutex.mutex)
    }
}