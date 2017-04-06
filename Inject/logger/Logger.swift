//
//  Logger.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `LogManager` is singleton that collects different log specifications and to return them

open class LogManager {
    // MARK: inner classes

    /// `Level` describes the different severity levels of a log entry
    public enum Level : Int , Comparable, CustomStringConvertible {
        case all = 0
        case debug
        case info
        case warn
        case error
        case fatal
        case off

        // MARK: CustomStringConvertible

        public var description: String {
            switch self {
                case .off:
                    return "OFF"
                case .info:
                    return "INFO"
                case .warn:
                    return "WARN"
                case .debug:
                    return "DEBUG"
                case .error:
                    return "ERROR"
                case .fatal:
                    return "FATAL"
                case .all:
                    return "ALL"

            } // switch
        }
    }

    // `LogEntry` is an internal class that contains the log payload and is used by `LogManager.Log` implementations
    open class LogEntry {
        // MARK: instance data

        var level     : Level
        var logger    : String
        var message   : String
        var error     : Error?
        var stacktrace : Stacktrace?
        var thread    : String
        var file      : String
        var function  : String
        var line      : Int
        var column    : Int
        var timestamp : Date

        // MARK: init

        init(logger: String, level : Level, message: String, error : Error? = nil, stacktrace : Stacktrace? = nil, thread: String, file: String, function: String, line: Int, column: Int, timestamp : Date) {
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
    open class Logger {
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

        func addChild(_ logger : Logger) {
            logger.parent = self

            children.append(logger)
        }

        func inheritFrom(_ logger : Logger) {
            if inherit {
                for log in logger.allLogs {
                    self.allLogs.append(log)
                }
            }
        }

        func isApplicable(_ level : Level) -> Bool {
            return level.rawValue >= self.level.rawValue
        }

        func currentThreadName() -> String {
            if Thread.isMainThread {
                return "main"
            }
            else {
               if let threadName = Thread.current.name, !threadName.isEmpty {
                   return threadName
               }
                else {
                    return String(format:"%p", Thread.current)
                }
            }
        }

        // MARK: public api

        /// create a log entry
        /// - Parameter level: the severity level
        /// - Parameter message: the message - auto - closure
        open func log<T>(_ level : Level, error: Error? = nil, stackTrace : Stacktrace? = nil, message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            if isApplicable(level) {
                let msg = message()
                let entry = LogEntry(logger: path, level : level, message: "\(msg)", error: error, stacktrace : stackTrace, thread: currentThreadName(), file: file, function: function, line: line, column: column, timestamp : Date())

                for log in allLogs {
                    log.log(entry)
                } // for
            } // if
        }

        // convenience funcs

        /// create a log entry with severity info
        /// - Parameter message: the message - auto - closure
        open func info<T>( _ message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.info, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity warn
        /// - Parameter message: the message - auto - closure
        open func warn<T>( _ message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.warn, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity debug
        /// - Parameter message: the message - auto - closure
        open func debug<T>( _ message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.debug, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity error
        /// - Parameter message: the message - auto - closure
        open func error<T>(_ error: Error? = nil, stackTrace : Stacktrace = Stacktrace(frames: Thread.callStackSymbols), message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.error, error: error, stackTrace: stackTrace, message: message, file: file, function: function, line: line, column: column)
        }

        /// create a log entry with severity fatal
        /// - Parameter message: the message - auto - closure
        open func fatal<T>(_ error: Error? = nil, stackTrace : Stacktrace = Stacktrace(frames: Thread.callStackSymbols), message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
            log(.fatal, error: error, stackTrace: stackTrace, message: message, file: file, function: function, line: line, column: column)
        }
    }

    /// A `Log` is an endpoint that will store log entries ( e.g. console, file, etc. )
    open class Log {
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
        open func format(_ entry : LogManager.LogEntry) -> String {
            var result : String = formatter.format(entry)

            if colorize {
                result = LogFormatter.colorize(result, level: entry.level)
            }

            return result
        }

        // MARK: abstract

        func log(_ entry : LogManager.LogEntry) -> Void {
            precondition(false, "\(type(of: self)).log must be implemented")
        }
    }

    // MARK: static data

    static var instance = LogManager(initial: true) // just to make sure that instance is never nil :-)

    // this logger is used fot internal log entries on the console...

    static var fatalLogger = Logger(path: "", level: .all, logs: [
            ConsoleLog(
                    name: "fatal",
                    formatter: LogFormatter.timestamp()  + " - " + LogFormatter.message()
                    )
    ])

    // MARK: class funcs

    static func error<T>( _ message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
        fatalLogger.log(.error, message: message, file: file, function: function, line: line, column: column)
    }

    static func fatal<T>( _ message: @autoclosure () -> T, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Void {
        fatalLogger.log(.fatal, message: message, file: file, function: function, line: line, column: column)

        fatalError("\(message())")
    }

    /// Return a `Logger` given a specific class. This function will build the fully qualified class name and try to find an appropriate logger
    /// - Parameter forClass: the specific class
    /// - Returns a Logger
    open static func getLogger(forClass clazz : AnyClass) -> Logger {
        return instance.getLogger(forClass: clazz)
    }

    /// Return a `Logger` given a name. This will either return a direct matching logger or the next parent logger by stripping the last legs of the name
    /// - Parameter forName: the logger name
    /// - Returns a Logger
    open static func getLogger(forName name : String) -> Logger {
        return instance.getLogger(forName: name)
    }

    /// Return the singleton
    /// Returns: the singleton
    open static func getSingleton() -> LogManager {
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
    fileprivate init(initial : Bool) {
        registerLogger("", level: .off, logs: [])
    }

    /// Create a new `LogManager` which will overwrite the singleton!
    public init() {
        LogManager.instance = self // simply override...good enough
    }

    // MARK: internal

    func parentLogger(_ logger : Logger) -> Logger? {
        var path = logger.path

        while path.contains(".") {
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
            loggers[""] = Logger(path: "", level: .off, logs: [])
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

    open func log(_ name : String) -> Log {
        return logs[name]!
    }

    open func registerLog(_ log: Log) -> Self {
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
    open func registerLogger(_ path : String, level : Level, logs: [Log] = [], inherit : Bool = true) -> Self {
        mutex.synchronized {
            self.modifications += 1

            self.loggers[path] = Logger(path: path, level: level, logs: logs, inherit: inherit)
        }

        return self
    }

    /// Return a `Logger` given a specific class. This function will build the fully qualified class name and try to find an appropriate logger
    /// - Parameter forClass: the specific class
    /// - Returns: a Logger
    open func getLogger(forClass clazz : AnyClass) -> Logger {
        return getLogger(forName: Classes.className(clazz, qualified: true))
    }

    /// Return a `Logger` given a name. This will either return a direct matching logger or the next parent logger by stripping the last legs of the name
    /// - Parameter forName: the logger name
    /// - Returns: a Logger
    open func getLogger(forName path : String) -> Logger {
        var logger : Logger?

        func find(_ name: String) -> Logger? {
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
                self.cachedLoggers.removeAll(keepingCapacity: true); // restart from scratch

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
