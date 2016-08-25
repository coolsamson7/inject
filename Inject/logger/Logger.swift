//
//  Logger.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `LogManager` is singleton that collects different log specifications and to return them

public class LogManager {
    // MARK: inner classes

    /// `Level` describes the different severity levels of a log entry
    public enum Level : Int , Comparable, CustomStringConvertible {
        case ALL = 0
        case DEBUG
        case INFO
        case WARN
        case ERROR
        case FATAL
        case OFF

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

    // `LogEntry` is an internal class that contains the log payload and is used by `LogManager.Log` implementations
    public class LogEntry {
        // MARK: instance data

        var level     : Level
        var logger    : String
        var message   : String
        var error     : ErrorType?
        var stacktrace : Stacktrace?
        var thread    : String
        var file      : String
        var function  : String
        var line      : Int
        var column    : Int
        var timestamp : NSDate

        // MARK: init

        init(logger: String, level : Level, message: String, error : ErrorType? = nil, stacktrace : Stacktrace? = nil, thread: String, file: String, function: String, line: Int, column: Int, timestamp : NSDate) {
            self.logger   = logger
            self.level    = level
            self.error    = error
            self.stacktrace  = stacktrace
            self.message  = message
            self.thread   = thread
            self.file     = file
            self.function = function
            self.line     = line
            self.column   = column

            self.timestamp = timestamp
        }
    }

    /// A `Logger` is used to emit log methods and is basically defined  by
    /// * a dot separated path
    /// * a severity level
    /// * a list of `Log` instances
    public class Logger {
        // MARK: instance data

        internal var path : String
        var level : Level
        var inherit = true
        var parent : Logger? = nil
        var children : [Logger] = []
        var logs: [Log] = []

        var allLogs:  [Log] = []

        // MARK: init

        init(path : String, level : Level, logs: [Log], inherit : Bool = true) {
            self.path = path
            self.level = level
            self.inherit = inherit
            self.logs = logs
        }

        // MARK: internal

        func reset() {
            parent = nil
            children = []
            allLogs = logs
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
                for log in logger.allLogs {
                    self.allLogs.append(log)
                }
            }
        }

        func isApplicable(level : Level) -> Bool {
            return level.rawValue >= self.level.rawValue
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

        /// create a log entry
        /// - Parameter level: the severity level
        /// - Parameter message: the message - auto - closure
        public func log<T>(level : Level, error: ErrorType? = nil, stackTrace : Stacktrace? = nil, @autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            if isApplicable(level) {
                let msg = message()
                let entry = LogEntry(logger: path, level : level, message: "\(msg)", error: error, stacktrace : stackTrace, thread: currentThreadName(), file: file, function: function, line: line, column: column, timestamp : NSDate())

                for log in allLogs {
                    log.log(entry)
                } // for
            } // if
        }

        // convenience funcs

        /// create a log entry with severity info
        /// - Parameter message: the message - auto - closure
        public func info<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.INFO, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity warn
        /// - Parameter message: the message - auto - closure
        public func warn<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.WARN, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity debug
        /// - Parameter message: the message - auto - closure
        public func debug<T>(@autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.DEBUG, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity error
        /// - Parameter message: the message - auto - closure
        public func error<T>(error: ErrorType? = nil, stackTrace : Stacktrace = Stacktrace(frames: NSThread.callStackSymbols()), @autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.ERROR, error: error, stackTrace: stackTrace, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity fatal
        /// - Parameter message: the message - auto - closure
        public func fatal<T>(error: ErrorType? = nil, stackTrace : Stacktrace = Stacktrace(frames: NSThread.callStackSymbols()), @autoclosure message: () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.FATAL, error: error, stackTrace: stackTrace, message: message, file: file, function: function, line: line, column: column)
        }
    }

    /// A `Log` is an endpoint that will store log entries ( e.g. console, file, etc. )
    public class Log {
        // MARK: static data

        static var defaultFormatter : LogFormatter = LogFormatter.timestamp() + " [" + LogFormatter.logger() + "] " + LogFormatter.level() + " - " + LogFormatter.message()

        // MARK: instance data

        var colorize : Bool
        var name : String
        var formatter : LogFormatter

        // MARK: init

        public init(name : String, formatter : LogFormatter? = nil, colorize : Bool = false) {
            self.name = name
            self.colorize = colorize
            self.formatter = formatter != nil ? formatter! : Log.defaultFormatter
        }

        // MARK: public

        /// format the given entry with the corresponding format
        /// - Parameter entry: the log entry
        /// - Returns: the formatted entry
        public func format(entry : LogManager.LogEntry) -> String {
            var result : String = formatter.format(entry)

            if colorize {
                result = LogFormatter.colorize(result, level: entry.level)
            }

            return result
        }

        // MARK: abstract

        func log(entry : LogManager.LogEntry) -> Void {
            precondition(false, "\(self.dynamicType).log must be implemented")
        }
    }

    // MARK: static data

    static var instance = LogManager(initial: true) // just to make sure that instance is never nil :-)

    // MARK: class funcs

    /// Return a `Logger` given a specific class. This function will build the fully qualified class name and try to find an appropriate logger
    /// - Parameter forClass: the specific class
    /// - Returns a Logger
    public static func getLogger(forClass clazz : AnyClass) -> Logger {
        return instance.getLogger(forClass: clazz)
    }

    /// Return a `Logger` given a name. This will either return a direct matching logger or the next parent logger by stripping the last legs of the name
    /// - Parameter forName: the logger name
    /// - Returns a Logger
    public static func getLogger(forName name : String) -> Logger {
        return instance.getLogger(forName: name)
    }

    /// Return the singleton
    /// Returns: the singleton
    public static func getSingleton() -> LogManager {
        return instance
    }

    // MARK: instance data

    var logs = [String: Log]()
    var loggers = [String:Logger]();

    var cachedLoggers = [String:Logger]();
    var modifications = 0;
    var mutex = Mutex()

    // MARK: init

    // this is the initial log manager
    private init(initial : Bool) {
        registerLogger("", level: .OFF, logs: [])
    }

    /// Create a new `LogManager` which will overwrite the singleton!
    public init() {
        LogManager.instance = self // simply override...good enough
    }

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
            loggers[""] = Logger(path: "", level: .OFF, logs: [])
        }

        // link parents

        for (_,logger) in loggers {
            if let parent = parentLogger(logger) {
                parent.addChild(logger)
            }
        }

        // inherit

        loggers[""]!.setup()
    }

    // MARK: public

    public func log(name : String) -> Log {
        return logs[name]!
    }

    public func registerLog(log: Log) -> Self {
        mutex.synchronized {
            self.modifications += 1

            self.logs[log.name] = log
        }

        return self
    }

    /// Register a logger
    /// - Parameter path: the path
    /// - Parameter level: the severity level
    /// - Parameter logs: a list of associated logs
    /// - Parameter inherit: if `true`, all `Log`s of the parent are inherited
    /// - Returns: Self
    public func registerLogger(path : String, level : Level, logs: [Log] = [], inherit : Bool = true) -> Self {
        mutex.synchronized {
            self.modifications += 1

            self.loggers[path] = Logger(path: path, level: level, logs: logs, inherit: inherit)
        }

        return self
    }

    /// Return a `Logger` given a specific class. This function will build the fully qualified class name and try to find an appropriate logger
    /// - Parameter forClass: the specific class
    /// - Returns: a Logger
    public func getLogger(forClass clazz : AnyClass) -> Logger {
        return getLogger(forName: Classes.className(clazz, qualified: true))
    }

    /// Return a `Logger` given a name. This will either return a direct matching logger or the next parent logger by stripping the last legs of the name
    /// - Parameter forName: the logger name
    /// - Returns: a Logger
    public func getLogger(forName path : String) -> Logger {
        var logger : Logger?

        func find(name: String) -> Logger? {
            var logger = self.cachedLoggers[name]
            if logger == nil {
                logger = self.loggers[name]
                if logger == nil {
                    let index = name.lastIndexOf(".")
                    logger = index != -1 ? find(name[0 ..< index]) : find("") // recursion
                } // if

                // and cache

                let newLogger = Logger(path : path, level : logger!.level, logs: logger!.logs) // create an artificial logger since otherwise we would get the inherited path...
                newLogger.inheritFrom(logger!)

                self.cachedLoggers[name] = newLogger

                logger = newLogger
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

// LogManager.Level

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