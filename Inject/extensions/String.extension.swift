//
//  String.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation


extension String {
    subscript(integerIndex: Int) -> Character {
        let index = startIndex.advancedBy(integerIndex)
        return self[index]
    }
    
    subscript(integerRange: Range<Int>) -> String {
        let start = startIndex.advancedBy(integerRange.startIndex)
        let end = startIndex.advancedBy(integerRange.endIndex)
        let range = start ..< end
        return self[range]
    }
    
    public func indexOf(target: String) -> Int {
        if let range = self.rangeOfString(target) {
            return startIndex.distanceTo(range.startIndex)
        }
        else {
            return -1
        }
    }
    
    public func lastIndexOf(target: String) -> Int {
        if let range = self.rangeOfString(target, options: .BackwardsSearch) {
            return startIndex.distanceTo(range.startIndex)
        }
        else {
            return -1
        }
    }
}