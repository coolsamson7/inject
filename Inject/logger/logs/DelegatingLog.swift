//
//  DelegatingLog.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `DelegatingLog` simply delegates all calls to a delegate
public class DelegatingLog<T : LogManager.Log> : LogManager.Log {
    // MARK: instance data

    var delegate : T?

    // MARK: init

    public init(name : String, delegate : T?) {
        self.delegate = delegate

        super.init(name: name)
    }

    // MARK: override LogManager.Log

    override func log(entry : LogManager.LogEntry) -> Void {
        delegate!.log(entry)
    }
}
