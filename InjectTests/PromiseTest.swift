//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class PromiseTest: XCTestCase {

    // MARK: local classes

    func testChain() {
        let promise = Promise<String>()
        let future = Future<String>()

        promise
        .then({$0 + "1"})
        .onSuccess({(str : String) -> Void in print(str)})
        .then({(str : String) -> String in return str + "1"})
        .onSuccess({(str : String) -> Void in print(str)})
        .then({$0 + "1"})
        .onSuccess({(str : String) -> Void in future.setResult(str)})

        promise.resolve("Super")

        let result = try! future.getResult()

        XCTAssert(result == "Super111")
    }

    func testPromiseReturn() {
        let queue = DispatchQueue(label: "logging-queue", attributes: [])

        let promise = Promise<String>()
        let future = Future<String>()

        promise
           .then({ (result : String) -> Promise<String> in let promise = Promise<String>(); queue.async(execute: {promise.resolve(result + "1")}); return promise})
           .onSuccess({(str : String) -> Void in future.setResult(str)})

        promise.resolve("test")

        let result = try! future.getResult()

        XCTAssert(result == "test1")
    }

    func testAll() {
        let p1 = Promise<String>()
        let p2 = Promise<String>()

        let promise = all(p1, p2)

        promise.onSuccess({ (result : (a : String, b : String)) -> Void in print("\(result.a) \(result.b)") })

        p1.resolve("p1")
        p2.resolve("p2")
    }
}
