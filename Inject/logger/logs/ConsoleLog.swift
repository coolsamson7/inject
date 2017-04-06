//
//  ConsoleLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// This log simply calls 'print()'
open class ConsoleLog: LogManager.Log {
    // MARK: init

    var mutex : Mutex?

    // MARK: init

    /// Create a new `ConsoleLog`
    /// - Parameter name: the log nam
    /// - Parameter formatter: the corresponding formatter
    /// - Parameter colorize: if `true`, the log entry weill be colorized
    /// - Parameter synchronize: if `true` the write operations is synchronized
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
                print(self.format(entry))
            }
        }
        else {
            print(self.format(entry))
        }
    }
}
