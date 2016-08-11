//
//  ConsoleDestination.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class FileDestination : LogManager.Destination {
    // MARK: init

    var mutex : Mutex?
    var fileHandle: NSFileHandle?

    // MARK: init

    init(name : String, fileName : String, formatter: LogFormatter, synchronize : Bool = true) throws {
        if synchronize {
            mutex = Mutex()
        }

        super.init(name: name, formatter: formatter)

        fileHandle = try openFile(fileName)
    }

    init(name : String, fileName : String, synchronize : Bool = true) throws {
        if synchronize {
            mutex = Mutex()
        }

        super.init(name: name, formatter: LogFormatter.timestamp() + " [" + LogFormatter.logger() + "] " + LogFormatter.level() + " - " + LogFormatter.message())

        fileHandle = try openFile(fileName)
    }

    deinit {
       closeFile()
    }

    // MARK: internal

    func openFile(fileName : String) throws -> NSFileHandle {
        // possibly create

        if !NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            NSFileManager.defaultManager().createFileAtPath(fileName, contents: nil, attributes: nil)
        }

        // open

        if let handle = NSFileHandle(forWritingAtPath: fileName) {
            return handle
        }
        else {
            fatalError("could not open file \(fileName)")
        }
    }

    func closeFile() {
        fileHandle?.closeFile()
    }

    func reallyLog(entry : LogManager.LogEntry) -> Void {
        fileHandle!.seekToEndOfFile()

        if let data = format(entry).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            fileHandle!.writeData(data)
        }
    }

    // MARK: override Destination

    override func log(entry : LogManager.LogEntry) -> Void {
        if let mutex = self.mutex {
            mutex.synchronized {
                self.reallyLog(entry)
            }
        }
        else {
            reallyLog(entry)
        }
    }
}