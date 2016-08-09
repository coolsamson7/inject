//
// Created by Andreas Ernst on 19.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class Future<T> {
    // MARK: instance data

    var resolved = false
    var mutex : Mutex
    var condition : Condition
    var result : T? = nil
    var error : ErrorType? = nil

    // init

    init() {
        mutex = Mutex()
        condition = Condition(mutex: mutex)
    }

    // MARK: public

    func getResult() throws -> T {
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

    public func setResult(result : T) {
        mutex.synchronized({
            self.resolved = true
            self.result = result

            self.condition.signal()
        })
    }

    public func setError(error : ErrorType) {
        mutex.synchronized({
            self.resolved = true
            self.error = error

            self.condition.signal()
        })
    }
}
