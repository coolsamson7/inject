//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class LoggerTests: XCTestCase {
    // MARK: local classes

    func testLogger() {
        let logging = LogManager();

        let formatter = LogFormatter.timestamp("dd/M/yyyy, H:mm:s") + " [" + LogFormatter.logger() + "] " + LogFormatter.thread() + " " + LogFormatter.level() + " " + LogFormatter.file() + " " + LogFormatter.function() + " " + LogFormatter.line() + " - " + LogFormatter.message()
        //let consoleLogger = try! FileDestination(name: "file", fileName: "/Users/andreasernst/Documents/Projects/inject/log.txt") // ConsoleDestination(name: "console", formatter: formatter)
        let consoleLogger = ConsoleDestination(name: "console", formatter: formatter)

        logging
           .registerLogger("", level : .OFF, destinations : [AsyncDestination(name: "console", delegate: consoleLogger)])
           .registerLogger("com", level : .WARN, inherit: true)
           .registerLogger("com.foo", level : .ALL, inherit: true)

        logging.getLogger("").warn("ouch 1")
        logging.getLogger("com").warn("ouch 2")

        let logger = logging.getLogger("com.foo")

        logger.warn("ouch 3")
        logger.debug("ouch 3")
        logger.error("ouch 3")
        logger.fatal("ouch 3")
    }
}