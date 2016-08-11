//
//  NSLogLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// This log calls 'NSLog'
public class NSLogLog: LogManager.Log {
    // MARK: init

    var mutex : Mutex?

    // MARK: init

    init(name : String, formatter: LogFormatter, synchronize : Bool = true) {
        if synchronize {
            mutex = Mutex()
        }

        super.init(name: name, formatter: formatter)
    }

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
                NSLog("%@", self.format(entry))
            }
        }
        else {
            NSLog("%@", self.format(entry))
        }
    }
}