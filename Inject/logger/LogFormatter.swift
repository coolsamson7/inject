//
//  LogFormatter.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class LogFormatter {
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

    public static func colorize<T>(object: T, level: LogManager.Level) -> String {
        let color = colors[level.rawValue - 1] // starts with OFF

        return "\(ESCAPE)fg\(color.r),\(color.g),\(color.b);\(object)\(RESET)"
    }

    // formatting api

    public class func string(value : String) -> LogFormatter{
        return LogFormatter { (entry) -> String in value }
    }

    public class func level() -> LogFormatter {
        return LogFormatter { $0.level.description }
    }

    public class func logger() -> LogFormatter {
        return LogFormatter { $0.logger }
    }

    public class func thread() -> LogFormatter {
        return LogFormatter { $0.thread }
    }

    public class func file() -> LogFormatter {
        return LogFormatter { $0.file }
    }

    public class func function() -> LogFormatter {
        return LogFormatter { $0.function }
    }

    public class func line() -> LogFormatter {
        return LogFormatter { String($0.line) }
    }

    public class func column() -> LogFormatter {
        return LogFormatter { String($0.column) }
    }

    public class func timestamp(pattern : String = "dd/M/yyyy, H:mm:s") -> LogFormatter {
        let dateFormatter = NSDateFormatter()

        dateFormatter.dateFormat = pattern

        return LogFormatter { dateFormatter.stringFromDate($0.timestamp ) }
    }

    public class func message() -> LogFormatter {
        return LogFormatter { $0.message }
    }

    // data

    let format : (LogManager.LogEntry) -> String

    // init

    init(format : (LogManager.LogEntry) -> String) {
        self.format = format
    }
}