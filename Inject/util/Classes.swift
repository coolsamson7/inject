//
//  Classes.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public enum ClassesErrors : Error, CustomStringConvertible {
    case exception(message: String)

    // CustomStringConvertible

    public var description: String {
        let builder = StringBuilder();

        switch self {
            case .exception(let message):
                builder.append("\(type(of: self)).Exception: ").append(message);
        } // switch

        return builder.toString()
    }
}

open class Classes {
    // private

    fileprivate class func bundleName(_ bundle : Bundle) -> String {
        return bundle.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    open class func setDefaultBundle(_ bundle : Bundle) {
        mainBundleName = bundleName(bundle)
    }

    open class func setDefaultBundle(_ clazz : AnyClass) {
        mainBundleName = bundleName(Bundle(for: clazz))
    }

    // data

    static var mainBundleName = Classes.bundleName(Bundle.main)

    // MARK: class funcs
    
    /// return a class instance given a class name
    open class func class4Name(_ className : String) throws -> AnyClass {
        var result : AnyClass? = NSClassFromString(className)

        if result != nil {
            return result!
        }
        else {
            if !className.contains(".") {
                result = NSClassFromString("\(mainBundleName).\(className)")
                if result != nil {
                    return result!
                }
            }
        } // else

        // darn

        throw ClassesErrors.exception(message: "no class named \"\(className)\"")
    }

    open class func className(_ clazz : AnyClass, qualified : Bool = false) -> String {
        if !qualified {
            return "\(clazz)"
        }
        else {
            return bundleName(Bundle(for: clazz)) + ".\(clazz)"
        }
    }
    
    // prevent
    
    fileprivate init() {}
}
