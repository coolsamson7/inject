//
//  ConsoleLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `FileLog` logs entries in a file
open class FileLog : LogManager.Log {
    // MARK: init

    var url : URL
    var mutex : Mutex?
    var fileHandle: FileHandle?

    // MARK: init

    /// Create a new `FileLog`
    /// - Parameter name: the log nam
    /// - Parameter fileName: the file name
    /// - Parameter formatter: the corresponding formatter
    /// - Parameter synchronize: if `true` the write operations is synchronized
    public init(name : String, fileName : String, formatter: LogFormatter? = nil, synchronize : Bool = true, colorize : Bool = false) throws {
        if synchronize {
            mutex = Mutex()
        }

        self.url = URL(fileURLWithPath: fileName)

        super.init(name: name, formatter: formatter, colorize: colorize)

        fileHandle = try openFile(fileName)
    }

    deinit {
       closeFile()
    }

    // MARK: public

    open func lastModificationDate() -> Date {
        let attributes = try! (url as NSURL).resourceValues(forKeys: [URLResourceKey.contentModificationDateKey, URLResourceKey.nameKey])

        return attributes[URLResourceKey.contentModificationDateKey] as! Date
    }

    // MARK: internal

    func openFile(_ fileName : String) throws -> FileHandle {
        // possibly create

        if !FileManager.default.fileExists(atPath: fileName) {
            FileManager.default.createFile(atPath: fileName, contents: nil, attributes: nil)
        }

        // open

        if let handle = FileHandle(forWritingAtPath: fileName) {
            return handle
        }
        else {
            LogManager.fatal("could not open file \(fileName)")

            fatalError("darn") // is already done by the fatal call
        }
    }

    func closeFile() {
        if fileHandle != nil {
            fileHandle?.closeFile()

            fileHandle = nil
        }
    }

    func reallyLog(_ entry : LogManager.LogEntry) -> Void {
        fileHandle!.seekToEndOfFile()

        if let data = (format(entry) + "\n").data(using: String.Encoding.utf8, allowLossyConversion: false) {
            fileHandle!.write(data)
        }
    }

    // MARK: override LogManager.Log

    override func log(_ entry : LogManager.LogEntry) -> Void {
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
