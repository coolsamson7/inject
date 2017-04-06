//
// Created by Andreas Ernst on 21.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import XCTest
import Foundation

@testable import Inject

class MapperTests: XCTestCase {
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
        var value : Float = 1.0

        override init() {
            super.init()
        }

        init(currency : String, value : Float) {
            self.currency = currency
            self.value = value
        }
    }

    class PersonMapper : Mapper {
        // init

        init() {
            super.init(mappings: [
                    Mapper.mapping(Person.self, targetClass: OtherPerson.self)
                       .map(Mapper.properties().except(["price", "prices"]))
                       .mapDeep("price", target: "price")
                       //.map("foo", target: "foo", mappingConversion: MappingConversion(sourceConversion: {$0}, targetConversion: {$0}))
                       .mapDeep("prices", target: "prices"),

                    Mapper.mapping(Money.self, targetClass: Money.self)
                       .map(Mapper.properties()) ]
                    )
        }
    }

    // lifecycle

    override class func setUp() {
        Tracer.setTraceLevel("mapper", level: .off)
        Tracer.setTraceLevel("beans", level: .off)
    }

    // test

    func testMapper() {
        let mapper = PersonMapper();

        // create a person

        let person = Person();
        person.name = "FOO";
        person.price = Money(currency: "shell", value: 1.0);
        person.prices.append(Money(currency: "shell", value: 1.0))

        // map

        let otherPerson = try! mapper.map(person, direction: .source_2_TARGET) as! OtherPerson // warm up

        XCTAssert(person.name == otherPerson.name)

        //try! Timer.measure({ //() -> Void in
        //    try mapper.map(person, direction: .SOURCE_2_TARGET)
        //}, times: 1)
    }
}
