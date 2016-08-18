//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

/// base protocol for different lock kinds
public protocol Lock {
    /// lock
    func lock() -> Void

    // unlock
    func unlock() -> Void
}
