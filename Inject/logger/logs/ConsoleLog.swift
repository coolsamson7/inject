//
//  ConsoleLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// Thos log simply calls 'print()'
public class ConsoleLog: LogManager.Log {
    // MARK: init

    var mutex : Mutex?

    // MARK: init

    /// Create a new ´ConsoleLog´
    /// - Parameter name: the log nam
    /// - Parameter formatter: the corresponding formatter
    /// - Parameter synchronize: if ´true´ the write operations is synchronized
    init(name : String, formatter: LogFormatter, synchronize : Bool = true) {
        if synchronize {
            mutex = Mutex()
        }

        super.init(name: name, formatter: formatter)
    }

    /// Create a new ´ConsoleLog´ with the default format
    /// - Parameter name: the log nam
    /// - Parameter formatter: the corresponding formatter
    /// - Parameter synchronize: if ´true´ the write operations is synchronized
    init(name : String, synchronize : Bool = true) {
        if synchronize {
            mutex = Mutex()
        }

        super.init(name: name)
    }

    // MARK: override Destination

    override func log(entry : LogManager.LogEntry) -> Void {
        if let mutex = self.mutex {
            mutex.synchronized {
                print(LogFormatter.colorize(self.format(entry), level: entry.level))
            }
        }
        else {
            print(self.format(entry))
        }
    }
}