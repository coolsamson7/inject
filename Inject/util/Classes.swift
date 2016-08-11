//
//  Classes.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public enum ClassesErrors : ErrorType, CustomStringConvertible {
    case Exception(message: String)

    // CustomStringConvertible

    public var description: String {
        let builder = StringBuilder();

        switch self {
            case .Exception(let message):
                builder.append("\(self.dynamicType).Exception: ").append(message);
        } // switch

        return builder.toString()
    }
}

public class Classes {
    // private

    private class func bundleName(bundle : NSBundle) -> String {
        return bundle.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    public class func setDefaultBundle(bundle : NSBundle) {
        mainBundleName = bundleName(bundle)
    }

    public class func setDefaultBundle(clazz : AnyClass) {
        mainBundleName = bundleName(NSBundle(forClass: clazz))
    }

    // data

    static var mainBundleName = Classes.bundleName(NSBundle.mainBundle())

    // MARK: class funcs
    
    /// return a class instance given a class name
    public class func class4Name(className : String) throws -> AnyClass {
        var result : AnyClass? = NSClassFromString(className)

        if result != nil {
            return result!
        }
        else {
            if !className.containsString(".") {
                result = NSClassFromString("\(mainBundleName).\(className)")
                if result != nil {
                    return result!
                }
            }
        } // else

        // darn

        throw ClassesErrors.Exception(message: "no class named \"\(className)\"")
    }

    public class func className(clazz : AnyClass, qualified : Bool = false) -> String {
        if !qualified {
            return "\(clazz)"
        }
        else {
            return bundleName(NSBundle(forClass: clazz)) + ".\(clazz)"
        }
    }
    
    // prevent
    
    private init() {}
}
