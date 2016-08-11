//
//  ConsoleDestination.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class ConsoleDestination : LogManager.Destination {
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
                print(self.format(entry))
            }
        }
        else {
            print(self.format(entry))
        }
    }
}