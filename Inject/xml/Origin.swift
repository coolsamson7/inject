//
//  Origin.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
public class Origin {
    // MARK: instance data
    
    var line : Int
    var column : Int
    
    // init
    
    init(line : Int, column : Int) {
        self.line = line
        self.column = column
    }
}
