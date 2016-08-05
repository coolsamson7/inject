//
//  FQN.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class FQN : Hashable, CustomStringConvertible {
    // instance data
    
    var namespace : String
    var key : String
    
    // class func
    
    class func fromString(str : String) -> FQN {
        let colon  = str.rangeOfString("=", range: str.startIndex..<str.endIndex)
        if colon != nil {
            let namespace = str[str.startIndex..<colon!.startIndex]
            let key = str[colon!.endIndex..<str.endIndex]
            
            return FQN(namespace: namespace, key: key)
        }
        else {
            return FQN(namespace: "", key: str)
        }
    }
    
    // init
    
    init(namespace : String, key : String) {
        self.namespace = namespace;
        self.key = key
    }
    
    // Hashable
    
    public var hashValue: Int {
        get {
            return namespace.hash &+ key.hash
        }
    }
    
    // CustomStringConvertible
    
    public var description: String {
        return "[namespace: \"\(namespace)\", key: \"\(key)\"]"
    }
}

public func ==(lhs: FQN, rhs: FQN) -> Bool {
    return lhs.namespace == rhs.namespace && lhs.key == rhs.key
}

