//
//  Origin.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
/// Stores information about the origin of a bean

public class Origin : CustomStringConvertible {
    // MARK: instance data

    var file : String
    var line : Int
    var column : Int
    
    // MARK: init
    
    init(file : String = "", line : Int, column : Int) {
        self.file = file
        self.line = line
        self.column = column
    }

    // MARK: implement CustomStringConvertible

    public var description: String {
        let builder = StringBuilder()

        if !file.isEmpty {
            builder.append("file: \(file)")
        }

        builder.append(" line: \(line), column: \(column)")

        return builder.toString()
    }
}
