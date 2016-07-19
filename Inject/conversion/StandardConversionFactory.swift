//
// StandardConversionFactory.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class StandardConversionFactory : ConversionFactory {
    // local classes
    
    public class Key : Hashable {
        // instance data
        
        var sourceType : Any.Type
        var targetType : Any.Type
        
        // init
        
        init(sourceType : Any.Type, targetType : Any.Type) {
            self.sourceType = sourceType;
            self.targetType = targetType
        }
        
        // Hashable
        
        public var hashValue: Int {
            get {
                return "\(sourceType)".hashValue &+ "\(targetType)".hashValue
            }
        }
    }
    
    // constant
    
    static var instance = StandardConversionFactory()
    
    // instance data
    
    var registry = [Key:Conversion]()
    
    // constructor
    
    init() {
        // String
        
        register(String.self, targetType: String.self, conversion: {$0})
        
        register(String.self, targetType: Bool.self, conversion: {$0 as! String == "true"})
        
        register(String.self, targetType: Int.self, conversion: {
            if let result = Int($0 as! String) {
                return result
            }
            else {
                throw ConversionErrors.ConversionException(value: $0, targetType: Int.self, context: nil)
            }
        })
        
        register(String.self, targetType: Float.self, conversion: {
            if let result = Float($0 as! String) {
                return result
            }
            else {
                throw ConversionErrors.ConversionException(value: $0, targetType: Float.self, context: nil)
            }
        })
        
        register(String.self, targetType: Double.self, conversion: {
            if let result = Double($0 as! String) {
                return result
            }
            else {
                throw ConversionErrors.ConversionException(value: $0, targetType: Double.self, context: nil)
            }
        })
        
        // Float
        
        register(Float.self, targetType: String.self, conversion: {String($0 as! Float)})
        register(Float.self, targetType: Int.self, conversion: {Int($0 as! Float)})
        
        // Int
        
        register(Int.self, targetType: String.self, conversion: {String($0 as! Int)})
        register(Int.self, targetType: Float.self, conversion: {Float($0 as! Int)})
        
        // Bool
        
        register(Bool.self, targetType: String.self, conversion: {($0 as! Bool) ? "true" : "false"})
    }
    
    // methods
    
    func register(sourceType : Any.Type, targetType : Any.Type, conversion : Conversion) -> Void {
        registry[Key(sourceType : sourceType, targetType : targetType)] = conversion
    }
    
    func hasConversion(sourceType : Any.Type, targetType : Any.Type) -> Bool {
        return registry[Key(sourceType : sourceType, targetType : targetType)] != nil
    }
    
    func getConversion(sourceType : Any.Type, targetType : Any.Type) throws -> Conversion {
        if let conversion = registry[Key(sourceType : sourceType, targetType : targetType)] {
            return conversion
        }
        else {
            throw ConversionErrors.UnknownConversion(sourceType: sourceType, targetType: targetType)
        }
    }
    
    func findConversion(sourceType : Any.Type, targetType : Any.Type) -> Conversion? {
        return registry[Key(sourceType : sourceType, targetType : targetType)]
    }
}

public func ==(lhs: StandardConversionFactory.Key, rhs: StandardConversionFactory.Key) -> Bool {
    return lhs.sourceType == rhs.sourceType && lhs.targetType == rhs.targetType
}
