//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

protocol FactoryBean {
    func create() throws -> AnyObject
}
