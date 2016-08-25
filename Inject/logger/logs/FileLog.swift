//
//  ConsoleLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `FileLog` logs entries in a file
public class FileLog: LogManager.Log {
    // MARK: init

    var mutex : Mutex?
    var fileHandle: NSFileHandle?

    // MARK: init

    /// Create a new `FileLog`
    /// - Parameter name: the log nam
    /// - Parameter fileName: the file name
    /// - Parameter formatter: the corresponding formatter
    /// - Parameter synchronize: if `true` the write operations is synchronized
    init(name : String, fileName : String, formatter: LogFormatter? = nil, synchronize : Bool = true, colorize : Bool = false) throws {
        if synchronize {
            mutex = Mutex()
        }

        super.init(name: name, formatter: formatter, colorize: colorize)

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

    // MARK: override LogManager.Log

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