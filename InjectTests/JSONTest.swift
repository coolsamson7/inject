//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class JSONTests: XCTestCase {
    // local classes

    class Person : NSObject {
        var name : String = "andi"
        var price : Money? = nil// Money()
        var prices : [Money] = [Money]()
        var age : Int = 51
        var weight : Int = 87

    }

    class OtherPerson : NSObject {
        var name : String = "andi"
        var age : Int = 0
        var weight : Float = 87.1
        var price : Money? = nil// Money()
        var prices : [Money] = [Money]()
    }

    class Money : NSObject {
        var currency = "EU"
        var value = 1.0
    }

    // lifecycle

    override class func setUp() {
        Tracer.setTraceLevel("mapper", level: .FULL)
    }

    // test

    func testJSON() {
        // create a person

        let person = Person();

        person.name = "FOO";
        person.price = Money();
        person.prices.append(Money())

        // define mapper

        let mapping = JSON.mapping
        let properties = JSON.properties

        let jsonMapper = try! JSON(mappings:
           // Person

           mapping(Person.self)
              .map("name", json: "json-name")
              .map("age")
              .map("price", deep: true)
              .map("weight"),

            // Money

            mapping(Money.self)
               .map(properties().except("bar", "baz")))

        // bean -> json

        let res = try! jsonMapper.asJSON(person)

        print(res)

        // json -> bean

        let jsonPerson = try! jsonMapper.fromJSON(Person.self, json: res)

        XCTAssert(person.name == jsonPerson.name)
        XCTAssert(person.price!.currency == jsonPerson.price!.currency)
        XCTAssert(person.price!.value == jsonPerson.price!.value)
    }
}