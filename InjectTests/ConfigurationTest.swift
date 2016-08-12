//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//


import XCTest
import Foundation

@testable import Inject


class ConfigurationTest: XCTestCase {
    // life cycle

    override class func setUp() {
        Classes.setDefaultBundle(ConfigurationTest.self)

        // set tracing

        Tracer.setTraceLevel("inject", level: .OFF)
        Tracer.setTraceLevel("configuration", level: .FULL)

        // set logging

        LogManager()
           .registerLogger("", level : .ALL, logs: [ConsoleLog(name: "console", synchronize: true)])
    }

    // test

    func testConfiguration() {
        let parentData = NSData(contentsOfURL: NSBundle(forClass: ConfigurationTest.self).URLForResource("configuration", withExtension: "xml")!)!

        ConfigurationNamespaceHandler(namespace: "configuration")

        let environment = try! Environment(name: "environment")

        try! environment
           .loadXML(parentData)
           .refresh()

        print(environment.report())

        let configurationManager = environment.getConfigurationManager()

        print(configurationManager.report())

        let string = try! configurationManager.getValue(String.self, namespace: "com.foo", key: "string")
        let int    = try! configurationManager.getValue(Int.self, namespace: "com.foo", key: "int")
        let bool   = try! configurationManager.getValue(Bool.self, namespace: "com.foo", key: "bool")

        XCTAssert(string == "hello")
        XCTAssert(int == 1)
        XCTAssert(bool == true)
    }
}

