//
//  LogFormatter.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// `LogFormatter` is used to compose a format for a log entry. A number of funcs are provided that reference the individual parts of a log entry - level, message,timestamp, etc. -
/// The complete layout is achieved by simply concatenating the individual results with the '+' operator.  A second '+' operator will handle strings.
open class LogFormatter {
    // MARK: local classes

    struct Color {
        // MARK: Instance data

        var r : Int
        var g : Int
        var b : Int

        init(r : Int, g : Int, b : Int) {
            self.r = r
            self.g = g
            self.b = b
        }
    }

    // MARK: static data

    static var colors: [Color] = [
            Color(r: 120, g: 120, b: 120),
            Color(r: 0,   g: 180, b: 180),
            Color(r: 0,   g: 150, b: 0),
            Color(r: 255, g: 190, b: 0),
            Color(r: 255, g: 0,   b: 0),
            Color(r: 160, g: 32,  b: 240)
    ]

    static let ESCAPE = "\u{001b}["
    static let RESET_FG = ESCAPE + "fg;" // Clear any foreground color
    static let RESET_BG = ESCAPE + "bg;" // Clear any background color
    static let RESET = ESCAPE + ";"      // Clear any foreground or background color

    // class funcs

    open static func colorize<T>(_ object: T, level: LogManager.Level) -> String {
        let color = colors[level.rawValue - 1] // starts with OFF

        return "\(ESCAPE)fg\(color.r),\(color.g),\(color.b);\(object)\(RESET)"
    }

    // formatting api

    /// return a formatter that contains a fixed string
    /// - Parameter vale: a string value
    /// - Returns: the formatter
    open class func string(_ value : String) -> LogFormatter{
        return LogFormatter { (entry) -> String in value }
    }

    /// return a formatter referencing the level part
    /// - Returns: the formatter
    open class func level() -> LogFormatter {
        return LogFormatter { $0.level.description }
    }

    /// return a formatter referencing the logger part
    /// - Returns: the formatter
    open class func logger() -> LogFormatter {
        return LogFormatter { $0.logger }
    }

    /// return a formatter referencing the thread part
    /// - Returns: the formatter
    open class func thread() -> LogFormatter {
        return LogFormatter { $0.thread }
    }

    /// return a formatter referencing the file part
    /// - Returns: the formatter
    open class func file() -> LogFormatter {
        return LogFormatter { $0.file }
    }

    /// return a formatter referencing the function part
    /// - Returns: the formatter
    open class func function() -> LogFormatter {
        return LogFormatter { $0.function }
    }

    /// return a formatter referencing the line part
    /// - Returns: the formatter
    open class func line() -> LogFormatter {
        return LogFormatter { String($0.line) }
    }

    /// return a formatter referencing the column part
    /// - Returns: the formatter
    open class func column() -> LogFormatter {
        return LogFormatter { String($0.column) }
    }

    /// return a formatter referencing the timestamp part
    /// - Parameter pattern: the date pattern which defaults to  "dd/M/yyyy, H:mm:s"
    /// - Returns: the formatter
    open class func timestamp(_ pattern : String = "dd/M/yyyy, H:mm:s") -> LogFormatter {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = pattern

        return LogFormatter { return dateFormatter.string(from: $0.timestamp) }
    }

    /// return a formatter referencing the message part
    /// Returns: the formatter
    open class func message() -> LogFormatter {
        func message(_ logEntry : LogManager.LogEntry) -> String {
            let builder = StringBuilder()

            builder.append(logEntry.message)

            if let error = logEntry.error {
                builder.append(" ").append("\(error)")
            }

            if let stacktrace = logEntry.stacktrace {
                builder.append("\n").append(stacktrace)
            }

            return builder.toString()
        }

        return LogFormatter { message($0) }
    }

    // data

    let format : (LogManager.LogEntry) -> String

    // init

    public init(format : @escaping (LogManager.LogEntry) -> String) {
        self.format = format
    }
}

// LogFormatter

/// concatenate two formatters
public func + (left: LogFormatter, right: LogFormatter) -> LogFormatter {
    return LogFormatter {return left.format($0) + right.format($0)}
}

/// concatenate a formatter and a string
public func + (left: LogFormatter, right: String) -> LogFormatter {
    return LogFormatter {return left.format($0) + right}
}
