//
//  QueuedLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `QueuedLog` is a delegating log that executes all log requests asynchronously by queuing to a dispatch queue
open class QueuedLog<T : LogManager.Log> : DelegatingLog<T> {
    // MARK: instance data

    var queue : DispatchQueue

    // MARK: init

    /// create a new `QueuedLog`
    /// - Parameter name: the log name
    /// - Parameter delegate: the delegate log
    /// - Parameter queue: a specific queue which defaults to a serial queue named 'logging-queue'
    public init(name : String, delegate : T?, queue : DispatchQueue? = nil) {
        if queue != nil {
            self.queue = queue!

        }
        else {
            self.queue = DispatchQueue(label: "logging-queue", attributes: [])
        }

        super.init(name: name, delegate: delegate)
    }

    // MARK: override LogManager.Log

    override func log(_ entry : LogManager.LogEntry) -> Void {
        queue.async(execute: {self.delegate!.log(entry)})
    }
}
