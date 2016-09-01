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
public class RollingFileLog : DelegatingLog<FileLog> {
    // MARK: init

    var fileManager = NSFileManager.defaultManager()
    var calendar = NSCalendar.currentCalendar()
    var mutex = Mutex()
    var baseName : String
    var dateFormatter = NSDateFormatter()
    var keepDays : Int
    var directory : NSURL? = nil
    var regexp : NSRegularExpression
    var mostRecentLog : NSDate?

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

        let exists = fileManager.fileExistsAtPath(logName())
        mostRecentLog = NSDate()
        delegate = try! createFileLog()

        if exists {
            mostRecentLog = delegate!.lastModificationDate()
        }

        // initial cleanup

        try cleanup(NSDate())
    }

    // MARK: internal

    func dateRegex(pattern : String) -> String {
        //regexp = try NSRegularExpression(pattern: "\\b([a-z|_|A-Z|\\-]+)\\-(\\d{4}\\-\\d{2}\\-\\d{2})\\.log\\b", options: [])


        return ""
    }

    public func createLogDirectory(directoryPath : String)  throws -> NSURL {
        let url = NSURL(fileURLWithPath: directoryPath, isDirectory: true)

        do {
            try fileManager.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            LogManager.fatal("could not create root directory \(directoryPath)")
        }

        return url
    }

    func logName(forDate date : NSDate? = nil) -> String {
        if date != nil {
            return directory!.path! + "/" + baseName + "-" + formatDate(date!) + ".log"
        }
        else {
            return directory!.path! + "/" + baseName + ".log"
        }
    }

    func createFileLog() throws -> FileLog {
        return try FileLog(name: name, fileName: logName(), formatter: formatter, synchronize: false)
    }

    func lookupCopies(url : NSURL) throws -> [(url: NSURL, date: NSDate)] {
        var files : [NSURL] = try fileManager.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: [])

        files.sortInPlace({$0.lastPathComponent! < $1.lastPathComponent!}) // actually not needed when comparing days...

        return files.filter({try! nameAndDate($0.lastPathComponent!).name != nil}).map({ ($0, try! nameAndDate($0.lastPathComponent!).date!) })
    }

    func cleanup(now : NSDate) throws {
        // copy current log

        if mostRecentLog != nil && daysBetween(now, and: mostRecentLog!) > 0 {
            // copy current to historic

            do {
                try fileManager.moveItemAtPath(logName(), toPath: logName(forDate: mostRecentLog))
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
                        try fileManager.removeItemAtURL(copy.url)
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

    func nameAndDate(fileName: String) throws -> (name : String?, date : NSDate?) {
        var results : [String] = []

        let matches = regexp.matchesInString(fileName, options: [], range: NSRange(location: 0, length: fileName.characters.count))

        for match in matches {
            for n in 0..<match.numberOfRanges {
                let range = match.rangeAtIndex(n)

                let r = fileName.startIndex.advancedBy(range.location)..<fileName.startIndex.advancedBy(range.location+range.length)

                results.append(fileName.substringWithRange(r))
            }
        }

        if results.count == 3 {
            return (results[1], parseDate(results[2]))
        }
        else {
            return (nil, nil)
        }
    }

    func daysBetween(date1 : NSDate, and date2 : NSDate) -> Int {
        return calendar.components(.Day, fromDate: calendar.startOfDayForDate(date1), toDate: calendar.startOfDayForDate(date2), options: []).day
    }

    func formatDate(date : NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }

    func parseDate(date : String) -> NSDate {
        return dateFormatter.dateFromString(date)!
    }

    class func createFileLog(name: String, fileName: String, formatter: LogFormatter?) throws -> FileLog {
        return try FileLog(name: name, fileName: fileName, formatter: formatter, synchronize: false)
    }

    // MARK: override LogManager.Log

    override func log(entry : LogManager.LogEntry) -> Void {
        mutex.synchronized {
            if self.daysBetween(entry.timestamp, and: self.mostRecentLog!) > 0 {
                try! self.cleanup(entry.timestamp)
            }

            self.mostRecentLog = entry.timestamp

            // delegate

            self.delegate!.log(entry)
        }
    }
}