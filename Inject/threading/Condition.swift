//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// A wrapper for `pthread_cond_t`
open class Condition {
    // MARK: instance data

    fileprivate var cond = pthread_cond_t()
    fileprivate var mutex : Mutex

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
    open func broadcast(){
        pthread_cond_broadcast(&cond)
    }

    /// Signal
    open func signal(){
        pthread_cond_signal(&cond)
    }

    /// wait on this condition
    open func wait(){
        pthread_cond_wait(&cond, &mutex.mutex)
    }
}
