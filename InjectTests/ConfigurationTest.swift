//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//


import XCTest
import Foundation

@testable import Inject


class ConfigurationTest: XCTestCase {


    func testConfiguration() {
        Tracer.setTraceLevel("loader", level: .FULL)
        let parentData = NSData(contentsOfURL: NSBundle(forClass: ConfigurationTest.self).URLForResource("configuration", withExtension: "xml")!)!

        ConfigurationNamespaceHandler(namespace: "configuration")

        let context = try! ApplicationContext(
                parent: nil,
                data: parentData
                )

        let configurationManager = context.getConfigurationManager()

        let string = try! configurationManager.getValue(String.self, namespace: "com.foo", key: "string")
        let int    = try! configurationManager.getValue(Int.self, namespace: "com.foo", key: "int")
        let bool   = try! configurationManager.getValue(Bool.self, namespace: "com.foo", key: "bool")

        XCTAssert(string == "hello")
        XCTAssert(int == 1)
        XCTAssert(bool == true)

    }
}

