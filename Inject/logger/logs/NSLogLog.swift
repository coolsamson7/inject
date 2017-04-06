//
//  NSLogLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// This log calls 'NSLog'
open class NSLogLog: LogManager.Log {
    // MARK: init

    var mutex : Mutex?

    // MARK: init

    public init(name : String, formatter: LogFormatter? = nil, synchronize : Bool = true, colorize : Bool = false) {
        if synchronize {
            mutex = Mutex()
        }

        super.init(name: name, formatter: formatter, colorize: colorize)
    }

    // MARK: override LogManager.Log

    override func log(_ entry : LogManager.LogEntry) -> Void {
        if let mutex = self.mutex {
            mutex.synchronized {
                NSLog("%@", self.format(entry))
            }
        }
        else {
            NSLog("%@", self.format(entry))
        }
    }
}
