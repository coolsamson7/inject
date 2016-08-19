//
//  FQN.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `FQN` is a fully qualified name containing a namespace and a key
public class FQN : Hashable, CustomStringConvertible {
    // MARK: instance data
    
    var namespace : String
    var key : String
    
    // MARK: class func
    
    public class func fromString(str : String) -> FQN {
        let colon  = str.rangeOfString(":", range: str.startIndex..<str.endIndex)
        if colon != nil {
            let namespace = str[str.startIndex..<colon!.startIndex]
            let key = str[colon!.endIndex..<str.endIndex]
            
            return FQN(namespace: namespace, key: key)
        }
        else {
            return FQN(namespace: "", key: str)
        }
    }
    
    // MARK: init
    
    init(namespace : String = "", key : String) {
        self.namespace = namespace;
        self.key = key
    }
    
    // Hashable
    
    public var hashValue: Int {
        get {
            return namespace.hash &+ key.hash
        }
    }
    
    // MARK: implement CustomStringConvertible
    
    public var description: String {
        return "[namespace: \"\(namespace)\", key: \"\(key)\"]"
    }
}

public func ==(lhs: FQN, rhs: FQN) -> Bool {
    return lhs.namespace == rhs.namespace && lhs.key == rhs.key
}

