//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class LoggerTests: XCTestCase {
    // MARK: local classes

    class TestLog: LogManager.Log {
        // MARK: data

        var callback : (LogManager.LogEntry) -> Void


        // MARK: init

        init(name : String, formatter: LogFormatter, callback: @escaping (LogManager.LogEntry) -> Void) {
            self.callback = callback

            super.init(name: name, formatter: formatter, colorize: false)
        }

        // MARK: override Destination

        override func log(_ entry : LogManager.LogEntry) -> Void {
            print(format(entry))
            
            callback(entry)
        }
    }


    // MARK: local classes

    /*func testRollingFile() throws {
        let manager = LogManager();

        let formatter = LogFormatter.timestamp("dd/M/yyyy, H:mm:s") + " [" + LogFormatter.logger() + "] " + LogFormatter.thread() + " " + LogFormatter.level() + " " + LogFormatter.file() + " " + LogFormatter.function() + " " + LogFormatter.line() + " - " + LogFormatter.message()

        manager
        .registerLogger("", level : .ALL, logs: [try RollingFileLog(name: "log", directory: "/Users/andreasernst/Documents/Projects/inject/", baseName: "log",formatter: formatter, keepDays: 2 )])

        manager.getLogger(forName: "").info("hellooooo")
    }*/

    func testLogger() {
        let manager = LogManager();

        let formatter = LogFormatter.timestamp("dd/M/yyyy, H:mm:s") + " [" + LogFormatter.logger() + "] " + LogFormatter.thread() + " " + LogFormatter.level() + " " + LogFormatter.file() + " " + LogFormatter.function() + " " + LogFormatter.line() + " - " + LogFormatter.message()

        var logs = 0
        let testLog = TestLog(name: "console", formatter: formatter, callback: {_ in 
            logs += 1
        })

        manager
           .registerLogger("", level : .off, logs: [testLog])
           .registerLogger("com", level : .warn, inherit: true)
           .registerLogger("com.foo", level : .all, inherit: true)

        var logger : LogManager.Logger = manager.getLogger(forName: "")

        // test 1

        XCTAssert(logger.path == "")

        // log something

        logger.debug("")
        logger.fatal(message: "")

        XCTAssert(logs == 0) // it's OFF dumbass!

        // test 2

        logger = manager.getLogger(forName: "com.bar")

        XCTAssert(logger.path == "com.bar")

        logs = 0

        // ALL = 0
        // DEBUG
        // INFO
        // WARN <-
        // ERROR
        // FATAL
        // OFF

        logger.debug("com")
        logger.info("com")
        logger.warn("com")
        logger.fatal(BeanDescriptorErrors.exception(message: "ouch"), message: "com")

        XCTAssert(logs == 2)
    }
}
