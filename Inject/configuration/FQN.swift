//
//  FQN.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// A `FQN` is a fully qualified name containing a namespace and a key
open class FQN : Hashable, CustomStringConvertible {
    // MARK: instance data
    
    var namespace : String
    var key : String
    
    // MARK: class func
    
    open class func fromString(_ str : String) -> FQN {
        let colon  = str.range(of: ":")
        if colon != nil {
            let namespace = str[str.startIndex..<colon!.lowerBound]
            let key = str[colon!.upperBound..<str.endIndex]
            
            return FQN(namespace: namespace, key: key)
        }
        else {
            return FQN(namespace: "", key: str)
        }
    }
    
    // MARK: init

    public init(namespace : String = "", key : String) {
        self.namespace = namespace;
        self.key = key
    }
    
    // Hashable
    
    open var hashValue: Int {
        get {
            return namespace.hash &+ key.hash
        }
    }
    
    // MARK: implement CustomStringConvertible
    
    open var description: String {
        return "[namespace: \"\(namespace)\", key: \"\(key)\"]"
    }
}

public func ==(lhs: FQN, rhs: FQN) -> Bool {
    return lhs.namespace == rhs.namespace && lhs.key == rhs.key
}

