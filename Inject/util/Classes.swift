//
//  Classes.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public class Classes {
    // MARK: class funcs
    
    /// Bla 
    class func class4Name(className : String) -> AnyClass {
        //if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleExecutable") as! String {
        //    let qualifiedName = "\(appName).\(className)"
        //}
        
        return NSClassFromString(className)!
    }
    
    class func className(clazz : AnyClass) -> String {
        return "\(clazz)"
    }
    
    class func unwrapOptional(type : Any.Type) -> AnyClass {
        return class4Name(Types.unwrapOptionalType(type))
    }
    
    // prevent
    
    private init() {}
}
