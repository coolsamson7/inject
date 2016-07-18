//
//  Classes.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class Types {
    // class funcs
    
    // TODO: this is just a hack...
    public class func unwrapOptionalType(type : Any.Type) -> String {
        var name = "\(type)"
        
        if name.containsString("<") {
            // e.g Swift.Optional<Foo>
            
            name = name[name.indexOf("<") + 1..<name.lastIndexOf(">")]
        }
        
        return name;
    }
    
    public class func normalizedType(object : AnyObject) -> Any.Type {
        var type : Any.Type = object.dynamicType
        
        if object is String {
            type = String.self
        }
        else if object is Float {
            type = Float.self
        }
        else if object is Double {
            type = Double.self
        }
        else if object is Int {
            type = Int.self
        }
        
        return type
    }
    
    // prevent
    
    private init() {}
}