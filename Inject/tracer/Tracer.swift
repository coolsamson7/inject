//
//  Tracer.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//


// tracer

func ==(lhs: Tracer.Level, rhs: Tracer.Level) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

func <(lhs: Tracer.Level, rhs: Tracer.Level) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func <=(lhs: Tracer.Level, rhs: Tracer.Level) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}

func >=(lhs: Tracer.Level, rhs: Tracer.Level) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}

func >(lhs: Tracer.Level, rhs: Tracer.Level) -> Bool {
    return lhs.rawValue > rhs.rawValue
}

public class Tracer {
    // -D DEBUG !
    #if DEBUG
    static var ENABLED = false
    #else
    static var ENABLED = false
    #endif
    // local classes
    
    enum Level : Int , Comparable {
        case OFF = 0
        case LOW
        case MEDIUM
        case HIGH
        case FULL
    }
    
    // data
    
    static var traceLevels = [String:Level](); // path -> trace-level
    static var cachedTraceLevels = [String:Level]();
    static var modifications = 0;
    
    static var formatter : NSDateFormatter = {
        var result = NSDateFormatter()
        
        result.dateFormat = "dd/M/yyyy, H:mm:s"
        
        return result
    }()
    
    // methods
    
    class func now() -> String {
        return formatter.stringFromDate(NSDate())
    }
    
    class func setTraceLevel(path : String, level : Level)  -> Void {
        traceLevels[path] = level;
        
        modifications++
    }
    
    class func getTraceLevel(path : String) -> Level {
        // check dirty state
        
        if modifications > 0 {
            cachedTraceLevels.removeAll(keepCapacity: true); // restart from scratch
            modifications = 0;
        } // if
        
        var level = cachedTraceLevels[path];
        if level == nil {
            level = traceLevels[path];
            if level == nil {
                let index = path.lastIndexOf(".");
                level = index != -1 ? getTraceLevel(path[0..<index]) : .OFF;
            } // if
            
            // cache
            
            cachedTraceLevels[path] = level
        } // if
        
        return level!
    }
    
    class func trace(path : String, level : Level, message : String) -> Void {
        if getTraceLevel(path).rawValue >= level.rawValue {
            // format
            
            print("\(now()) [\(path)]: \(message)")
        }
    }
}