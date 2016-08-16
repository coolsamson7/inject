//
//  QueuedLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `QueuedLog` is a delegating log that executes all log requests asynchronously by queuing to a dispatch queue
public class QueuedLog: DelegatingLog {
    // MARK: instance data

    var queue : dispatch_queue_t

    // MARK: init

    /// create a new `QueuedLog`
    /// - Parameter name: the log name
    /// - Parameter delegate: the delegate log
    /// - Parameter queue: a specific queue which defaults to a serial queue named 'logging-queue'
    init(name : String, delegate : LogManager.Log, queue : dispatch_queue_t? = nil) {
        if queue != nil {
            self.queue = queue!

        }
        else {
            self.queue = dispatch_queue_create("logging-queue", DISPATCH_QUEUE_SERIAL)
        }

        super.init(name: name, delegate: delegate)
    }

    // MARK: override Destination

    override func log(entry : LogManager.LogEntry) -> Void {
        dispatch_async(queue, {self.delegate.log(entry)})
    }
}