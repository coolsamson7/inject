
//
//  InjectBean.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
import Foundation

@objc(InjectBean)
public class InjectBean : Inject {
    // instance data
    
    var id : String?
    
    // init
    
    init(id : String? = nil) {
        self.id = id
    }
}