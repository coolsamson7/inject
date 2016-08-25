//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class JSONTests: XCTestCase {
    // local classes

    class Product: NSObject {
        // instance data

        var name : String = "andi"
        var price : Money? = nil// Money()
        var prices : [Money] = [Money]()
        var id : Int = 1
        var weight : Float = 100
    }

    class Money : NSObject {
        // instance data

        var currency = "EU"
        var value = 1.0

        override init() {
            super.init()
        }

        init(currency: String, value : Double) {
            self.currency = currency
            self.value = value
        }
    }

    // lifecycle

    override class func setUp() {
        Tracer.setTraceLevel("mapper", level: .FULL)
    }

    // test

    func testJSON() {
        // create a person

        let product = Product();

        product.name = "FOO";
        //person.price = Money();
        product.prices.append(Money())
        product.prices.append(Money())

        // define mapper

        let mapping = JSON.mapping
        let properties = JSON.properties

        let jsonMapper = try! JSON(mappings:
           // Person

           mapping(Product.self)
              .map("name", json: "json-name")
              .map("id")
              .map("price", deep: true)
              .map("prices", deep: true)
              .map("weight", conversions: Conversions(toTarget: {"\($0)"}, toSource: {Float($0)!})),

            // Money

            mapping(Money.self)
               .map(properties().except("bar", "baz")))

        // bean -> json

        let res = try! jsonMapper.asJSON(product)

        // json -> bean

        let result = try! jsonMapper.fromJSON(Product.self, json: res)

        XCTAssert(product.name == result.name)
        XCTAssert(product.prices.count == result.prices.count)
        //XCTAssert(product.price?.currency == product.price?.currency)
        //XCTAssert(product.price?.value == product.price?.value)
    }
}