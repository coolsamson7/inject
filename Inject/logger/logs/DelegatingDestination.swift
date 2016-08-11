//
//  DelegatingDestination.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class DelegatingLog: LogManager.Log {
    // MARK: instance data

    var delegate : LogManager.Log

    // MARK: init

    init(name : String, delegate : LogManager.Log) {
        self.delegate = delegate

        super.init(name: name)
    }

    // MARK: override Destination

    override func log(entry : LogManager.LogEntry) -> Void {
        delegate.log(entry)
    }
}
