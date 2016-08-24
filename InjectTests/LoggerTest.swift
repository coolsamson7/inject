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

        init(name : String, formatter: LogFormatter, callback: (LogManager.LogEntry) -> Void) {
            self.callback = callback

            super.init(name: name, formatter: formatter, colorize: false)
        }

        // MARK: override Destination

        override func log(entry : LogManager.LogEntry) -> Void { print(format(entry))
            callback(entry)
        }
    }


    // MARK: local classes

    func testLogger() {
        let manager = LogManager();

        let formatter = LogFormatter.timestamp("dd/M/yyyy, H:mm:s") + " [" + LogFormatter.logger() + "] " + LogFormatter.thread() + " " + LogFormatter.level() + " " + LogFormatter.file() + " " + LogFormatter.function() + " " + LogFormatter.line() + " - " + LogFormatter.message()

        var logs = 0
        var lastEntry : LogManager.LogEntry? = nil
        let testLog = TestLog(name: "console", formatter: formatter, callback: {
            logs += 1
            lastEntry = $0
        })

        manager
           .registerLogger("", level : .OFF, logs: [testLog])
           .registerLogger("com", level : .WARN, inherit: true)
           .registerLogger("com.foo", level : .ALL, inherit: true)

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

        //logger.debug("com")
        //logger.info("com")
        //logger.warn("com")
        logger.fatal(BeanDescriptorErrors.Exception(message: "ouch"), message: "com")

        //XCTAssert(logs == 2)
    }
}