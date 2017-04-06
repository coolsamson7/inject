//
//  String.extension.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

extension String {
    subscript(integerIndex: Int) -> Character {
        let index = characters.index(startIndex, offsetBy: integerIndex)
        return self[index]
    }

    subscript(integerRange: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: integerRange.lowerBound)
        let end = characters.index(startIndex, offsetBy: integerRange.upperBound)
        let range = start ..< end
        return self[range]
    }

    public func indexOf(_ target: String) -> Int {
        if let range = self.range(of: target) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        }
        else {
            return -1
        }
    }

    public func lastIndexOf(_ target: String) -> Int {
        if let range = self.range(of: target, options: .backwards) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        }
        else {
            return -1
        }
    }

    public func substring(from: Int) -> String {
       return self.substring(from: self.characters.index(self.startIndex, offsetBy: from))
    }
}
