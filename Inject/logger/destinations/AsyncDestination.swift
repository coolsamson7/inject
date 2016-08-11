//
//  AsyncDestination.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class AsyncDestination : DelegatingDestination {
    // MARK: instance data

    var queue : dispatch_queue_t;

    // MARK: init

    init(name : String, delegate : LogManager.Destination, queue : dispatch_queue_t? = nil) {
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