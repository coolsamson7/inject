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
        Tracer.setTraceLevel("mapper", level: .OFF)
    }

    // test

    func testJSON() {
        // create a person

        let person = Person();

        person.name = "FOO";
        person.price = Money();
        person.prices.append(Money())

        // define mapper

        let jsonMapper = try! JSON(mappings:
        JSON.mapping(Person.self)
        .map("name")
        .map("age")
        .map("price", deep: true)
        .map("weight"),

                JSON.mapping(Money.self)
                .map("currency")
                .map("value")
                )

        // bean -> json

        let res = try! jsonMapper.asJSON(person)

        print(res)

        // json -> bean

        let jsonPerson = try! jsonMapper.fromJSON(res) as! Person

        XCTAssert(person.name == jsonPerson.name)
        XCTAssert(person.price!.currency == jsonPerson.price!.currency)
        XCTAssert(person.price!.value == jsonPerson.price!.value)
    }
}