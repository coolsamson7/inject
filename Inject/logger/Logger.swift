//
//  Logger.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class LogManager {
    // MARK: inner classes

    public enum Level : Int , Comparable, CustomStringConvertible {
        case OFF = 0
        case DEBUG
        case INFO
        case WARN
        case ERROR
        case FATAL
        case ALL

        // MARK: CustomStringConvertible

        public var description: String {
            switch self {
                case .OFF:
                    return "OFF"
                case .INFO:
                    return "INFO"
                case .WARN:
                    return "WARN"
                case .DEBUG:
                    return "DEBUG"
                case .ERROR:
                    return "ERROR"
                case .FATAL:
                    return "FATAL"
                case .ALL:
                    return "ALL"

            } // switch
        }
    }

    public class LogEntry {
        // MARK: instance data

        var level    : Level
        var logger   : String
        var message  : String
        var thread: String
        var file     : String
        var function : String
        var line     : Int
        var column   : Int
        var timestamp : NSDate

        // MARK: init

        init(logger: String, level : Level, message: String, thread: String, file: String, function: String, line: Int, column: Int, timestamp : NSDate) {
            self.logger   = logger
            self.level    = level
            self.message  = message
            self.thread   = thread
            self.file     = file
            self.function = function
            self.line     = line
            self.column   = column

            self.timestamp = timestamp
        }
    }

    public class Logger {
        // MARK: instance data

        var path : String
        var level : Level
        var inherit = true
        var parent : Logger? = nil
        var children : [Logger] = []
        var destinations : [Destination] = []

        var allDestinations :  [Destination] = []

        // MARK: init

        init(path : String, level : Level, destinations : [Destination], inherit : Bool = true) {
            self.path = path
            self.level = level
            self.inherit = inherit
            self.destinations = destinations
        }

        // MARK: internal

        func reset() {
            parent = nil

            allDestinations = destinations
        }

        func setup() {
            for child in children {
                child.inheritFrom(self)

                child.setup() // recursion
            }
        }

        func addChild(logger : Logger) {
            logger.parent = self

            children.append(logger)
        }

        func inheritFrom(logger : Logger) {
            if inherit {
                for destination in logger.allDestinations {
                    self.allDestinations.append(destination)
                }
            }
        }

        func isApplicable(level : Level) -> Bool {
            return self.level.rawValue >= level.rawValue
        }

        func currentThreadName() -> String {
            if NSThread.isMainThread() {
                return "main"
            }
            else {
               if let threadName = NSThread.currentThread().name where !threadName.isEmpty {
                   return threadName
               }
                else {
                    return String(format:"%p", NSThread.currentThread())
                }
            }
        }

        // MARK: public api

        public func log<T>(level : Level, @autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            if isApplicable(level) {
                let msg = message()
                let entry = LogEntry(logger: path, level : level, message: "\(msg)", thread: currentThreadName(), file: file, function: function, line: line, column: column, timestamp : NSDate())

                for destination in allDestinations {
                    destination.log(entry)
                } // for
            } // if
        }

        // convenience funcs

        public func info<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.INFO, message: message, file: file, function: function, line: line, column: column)
        }

        public func warn<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.WARN, message: message, file: file, function: function, line: line, column: column)
        }

        public func debug<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.DEBUG, message: message, file: file, function: function, line: line, column: column)
        }

        public func error<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.ERROR, message: message, file: file, function: function, line: line, column: column)
        }

        public func fatal<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.FATAL, message: message, file: file, function: function, line: line, column: column)
        }
    }

    public class Destination {
        // MARK: instance data

        var name : String
        var formatter : LogFormatter

        // MARK: init

        init(name : String) {
            self.name = name
            self.formatter = LogFormatter.timestamp() + " [" + LogFormatter.logger() + "] " + LogFormatter.level() + " - " + LogFormatter.message()
        }

        init(name : String, formatter : LogFormatter) {
            self.name = name
            self.formatter = formatter
        }

        // TEST


        // TEST


        // MARK: public

        public func format(entry : LogManager.LogEntry) -> String {
            return formatter.format(entry)
        }

        // MARK: abstract

        func log(entry : LogManager.LogEntry) -> Void {
            // implement
        }
    }

    // MARK: instance data

    var destinations = [String:Destination]()
    var loggers = [String:Logger]();

    var cachedLoggers = [String:Logger]();
    var modifications = 0;
    var mutex = Mutex()

    // MARK: internal

    func parentLogger(logger : Logger) -> Logger? {
        var path = logger.path

        while path.containsString(".") {
            let index = path.lastIndexOf(".");
            path = path[0..<index]

            if loggers[path] != nil {
                return loggers[path]
            }
        }

        return path == "" ? nil : loggers[""]
    }

    func setupLoggers() -> Void {
        // reset

        for (_,logger) in loggers {
            logger.reset()
        }

        // check for root logger

        if loggers[""] == nil {
            loggers[""] = Logger(path: "", level: .ALL, destinations: [], inherit: false) // hmmm....
        }

        // link parents

        for (_,logger) in loggers {
            let parent = parentLogger(logger)
            if parent != nil {
                parent!.addChild(logger)
            }
        }

        // inherit

        loggers[""]!.setup()
    }

    // MARK: public

    public func destination(name : String) -> Destination {
        return destinations[name]!
    }

    public func registerDestination(destination : Destination) -> LogManager {
        mutex.synchronized {
            self.modifications += 1

            self.destinations[destination.name] = destination
        }

        return self
    }

    public func registerLogger(path : String, level : Level, destinations : [Destination] = [], inherit : Bool = true) -> LogManager {
        mutex.synchronized {
            self.modifications += 1

            self.loggers[path] = Logger(path: path, level: level, destinations: destinations, inherit: inherit)
        }

        return self
    }

    public func getLogger(forClass clazz : AnyClass) -> Logger {
        return getLogger(forName: Classes.className(clazz, qualified: true))
    }

    public func getLogger(forName path : String) -> Logger {
        var logger : Logger?

        func find(path : String) -> Logger? {
            var logger = self.cachedLoggers[path]
            if logger == nil {
                logger = self.loggers[path]
                if logger == nil {
                    let index = path.lastIndexOf(".")
                    logger = index != -1 ? find(path[0 ..< index]) : find("") // recursion
                } // if

                // and cache

                self.cachedLoggers[path] = logger
            } // if

            return logger
        }

        mutex.synchronized {
            // check dirty state

            if self.modifications > 0 {
                self.cachedLoggers.removeAll(keepCapacity: true); // restart from scratch

                // and reset loggers

                self.setupLoggers()

                self.modifications = 0;
            } // if

            logger = find(path)
        } // synchronized

        return logger!
    }
}

// LogFormatter

func + (left: LogFormatter, right: LogFormatter) -> LogFormatter {
    return LogFormatter {left.format($0) + right.format($0)}
}

func + (left: LogFormatter, right: String) -> LogFormatter {
    return LogFormatter {left.format($0) + right}
}

// Level

public func ==(lhs: LogManager.Level, rhs: LogManager.Level) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func <(lhs: LogManager.Level, rhs: LogManager.Level) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

public func <=(lhs: LogManager.Level, rhs: LogManager.Level) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}

public func >=(lhs: LogManager.Level, rhs: LogManager.Level) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}

public func >(lhs: LogManager.Level, rhs: LogManager.Level) -> Bool {
    return lhs.rawValue > rhs.rawValue
}