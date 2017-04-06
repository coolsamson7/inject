//
//  RollingFileLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `RollingFileLog` is a delegating log that changes filenames every day and keeps a number of old copies
/// the current name is
/// - <base-name>.log
/// - historical copies: <base-name>-yyyy-MM-dd.log
open class RollingFileLog : DelegatingLog<FileLog> {
    // MARK: init

    var fileManager = FileManager.default
    var calendar = Calendar.current
    var mutex = Mutex()
    var baseName : String
    var dateFormatter = DateFormatter()
    var keepDays : Int
    var directory : URL? = nil
    var regexp : NSRegularExpression
    var mostRecentLog : Date?

    // MARK: init

    /// Create a new `RollingFileLog`
    /// - Parameter name: the log name
    /// - Parameter directory: the directory name
    /// - Parameter baseName: the file name
    /// - Parameter formatter: the corresponding formatter
    public init(name : String, directory : String, baseName : String, formatter: LogFormatter? = nil, keepDays : Int) throws {
        self.baseName = baseName
        self.keepDays = keepDays

        // both must match so no parameter...hmmm

        dateFormatter.dateFormat = "yyyy-MM-dd"
        regexp = try NSRegularExpression(pattern: "\\b([a-z|_|A-Z|\\-]+)\\-(\\d{4}\\-\\d{2}\\-\\d{2})\\.log\\b", options: [])

        // super

        super.init(name: name, delegate: nil)

        self.directory = try createLogDirectory(directory)

        self.formatter = formatter != nil ? formatter! : LogManager.Log.defaultFormatter

        let exists = fileManager.fileExists(atPath: logName())
        mostRecentLog = Date()
        delegate = try! createFileLog()

        if exists {
            mostRecentLog = delegate!.lastModificationDate()
        }

        // initial cleanup

        cleanup(Date())
    }

    // MARK: internal

    func dateRegex(_ pattern : String) -> String {
        //regexp = try NSRegularExpression(pattern: "\\b([a-z|_|A-Z|\\-]+)\\-(\\d{4}\\-\\d{2}\\-\\d{2})\\.log\\b", options: [])


        return ""
    }

    open func createLogDirectory(_ directoryPath : String)  throws -> URL {
        let url = URL(fileURLWithPath: directoryPath, isDirectory: true)

        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            LogManager.fatal("could not create root directory \(directoryPath)")
        }

        return url
    }

    func logName(forDate date : Date? = nil) -> String {
        if date != nil {
            return directory!.path + "/" + baseName + "-" + formatDate(date!) + ".log"
        }
        else {
            return directory!.path + "/" + baseName + ".log"
        }
    }

    func createFileLog() throws -> FileLog {
        return try FileLog(name: name, fileName: logName(), formatter: formatter, synchronize: false)
    }

    func lookupCopies(_ url : URL) throws -> [(url: URL, date: Date)] {
        var files : [URL] = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])

        files.sort(by: {$0.lastPathComponent < $1.lastPathComponent}) // actually not needed when comparing days...

        return files.filter({try! nameAndDate($0.lastPathComponent).name != nil}).map({ ($0, try! nameAndDate($0.lastPathComponent).date!) })
    }

    func cleanup(_ now : Date) {
        // copy current log

        if mostRecentLog != nil && daysBetween(now, and: mostRecentLog!) > 0 {
            // copy current to historic

            do {
                try fileManager.moveItem(atPath: logName(), toPath: logName(forDate: mostRecentLog))
            }
            catch {
                LogManager.error("\(error) while trying to move \(logName())")
            }

            // create new

            delegate = try! createFileLog()
        }

        // cleanup the rest

       do {
            for copy in try lookupCopies(directory!) { // (url, date) sorted by name which contains the date...
                if daysBetween(copy.date, and: now) > keepDays {
                    do {
                        try fileManager.removeItem(at: copy.url)
                    }
                    catch {
                        LogManager.error("\(error) while trying to remove \(logName())")
                    }
                }
            } // for
       }
       catch {
           LogManager.error("\(error) while trying to lookup historic logs")
       }
    }

    func nameAndDate(_ fileName: String) throws -> (name : String?, date : Date?) {
        var results : [String] = []

        let matches = regexp.matches(in: fileName, options: [], range: NSRange(location: 0, length: fileName.characters.count))

        for match in matches {
            for n in 0..<match.numberOfRanges {
                let range = match.rangeAt(n)

                let r = fileName.characters.index(fileName.startIndex, offsetBy: range.location)..<fileName.characters.index(fileName.startIndex, offsetBy: range.location+range.length)

                results.append(fileName.substring(with: r))
            }
        }

        if results.count == 3 {
            return (results[1], parseDate(results[2]))
        }
        else {
            return (nil, nil)
        }
    }

    func daysBetween(_ date1 : Date, and date2 : Date) -> Int {
        return (calendar as NSCalendar).components(.day, from: calendar.startOfDay(for: date1), to: calendar.startOfDay(for: date2), options: []).day!
    }

    func formatDate(_ date : Date) -> String {
        return dateFormatter.string(from: date)
    }

    func parseDate(_ date : String) -> Date {
        return dateFormatter.date(from: date)!
    }

    class func createFileLog(_ name: String, fileName: String, formatter: LogFormatter?) throws -> FileLog {
        return try FileLog(name: name, fileName: fileName, formatter: formatter, synchronize: false)
    }

    // MARK: override LogManager.Log

    override func log(_ entry : LogManager.LogEntry) -> Void {
        mutex.synchronized {
            if self.daysBetween(entry.timestamp, and: self.mostRecentLog!) > 0 {
                self.cleanup(entry.timestamp)
            }

            self.mostRecentLog = entry.timestamp

            // delegate

            self.delegate!.log(entry)
        }
    }
}
