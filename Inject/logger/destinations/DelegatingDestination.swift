//
//  DelegatingDestination.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class DelegatingDestination : LogManager.Destination {
    // MARK: instance data

    var delegate : LogManager.Destination

    // MARK: init

    init(name : String, delegate : LogManager.Destination) {
        self.delegate = delegate

        super.init(name: name)
    }

    // MARK: override Destination

    override func log(entry : LogManager.LogEntry) -> Void {
        delegate.log(entry)
    }
}
