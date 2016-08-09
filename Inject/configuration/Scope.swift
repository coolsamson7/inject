//
//  Scope.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//


public class Scope : Hashable, CustomStringConvertible {
    static var WILDCARD = Scope()
    
    // MARK: instance data
    
    var path : [String]
    
    // init
    
    init(legs : String...) {
        path = legs
    }
    
    init(legs : [String]) {
        path = legs
    }
    
    // func
    
    func getParentScope() -> Scope? {
        if !isRoot() {
            let result = path
            
            path.removeLast()
            
            return Scope(legs: result)
        }
        else {
            return nil
        }
    }
    
    func isRoot() -> Bool {
        return path.count == 0
    }
    
    // Hashable
    
    public var hashValue: Int {
        get {
            var result = 0
            for leg in path {
                result = result &+ leg.hash
            }
            
            return result
        }
    }
    
    // CustomStringConvertible
    
    public var description: String {
        return path.reduce("",  combine: {($0.characters.count == 0 ? "" : $0 + ".") + $1})
    }
}

public func ==(lhs: Scope, rhs: Scope) -> Bool {
    if lhs.path.count != rhs.path.count {
        return false
    }
    
    for i in 0..<lhs.path.count {
        if lhs.path[i] != rhs.path[i] {
            return false
        }
    }
    return true
}