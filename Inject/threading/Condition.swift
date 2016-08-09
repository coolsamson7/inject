//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class Condition {
    // MARK: instance data

    private var cond = pthread_cond_t()
    private var mutex : Mutex

    // init

    public init(mutex : Mutex){
        self.mutex = mutex

        pthread_cond_init(&cond, nil)
    }

    deinit {
        pthread_cond_destroy(&cond)
    }

    // MARK: public

    func broadcast(){
        pthread_cond_broadcast(&cond)
    }

    func signal(){
        pthread_cond_signal(&cond)
    }

    func wait(){
        pthread_cond_wait(&cond, &mutex.mutex)
    }
}