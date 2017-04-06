//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public struct Timer : CustomStringConvertible {
    // MARK: class methods

    static func measure(_ block: (() throws -> Any?), times : Int = 1) throws -> Void {
        var timer = Timer();

        timer.start()

        for _ in 0..<times {
            try block()
        }

        timer.stop();

        print("\(times) loops in \(timer)")
    }

    // MARK: instance data

    var begin : CFAbsoluteTime
    var end   : CFAbsoluteTime

    // MARK: constructor

    public init() {
        begin = CFAbsoluteTimeGetCurrent()
        end = 0
    }

    // methods

    mutating func start() {
        begin = CFAbsoluteTimeGetCurrent()
        end = 0
    }

    mutating func stop() -> Double {
        if (end == 0) {
            end = CFAbsoluteTimeGetCurrent()
        }

        return Double(end - begin)
    }

    var duration:CFAbsoluteTime {
        get {
            if (end == 0) {
                return CFAbsoluteTimeGetCurrent() - begin
            }
            else {
                return end - begin
            }
        }
    }

    // CustomStringConvertible

    public var description:String {
        let time = duration

        if (time > 100) {
            return " \(time/60) min"
        }
        else if (time < 1e-6) {
            return " \(time*1e9) ns"
        }
        else if (time < 1e-3) {
            return " \(time*1e6) µs"
        }
        else if (time < 1) {
            return " \(time*1000) ms"
        }
        else {
            return " \(time) s"
        }
    }
}

