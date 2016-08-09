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
        // MARK: instance data
        
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
    
    // MARK: instance data
    
    var registry = [Key:Conversion]()
    
    // MARK: constructor


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
        //register(Float.self, targetType: Int.self, conversion: {Int($0 as! Float)})
        register(Float.self, targetType: Double.self, conversion: {Double($0 as! Float)})

        // Double

        register(Double.self, targetType: String.self, conversion: {String($0 as! Double)})
        //register(Float.self, targetType: Int.self, conversion: {Int($0 as! Float)})
        
        // Int
        
        register(Int.self, targetType: String.self, conversion: {String($0 as! Int)})
        register(Int.self, targetType: Float.self, conversion: {Float($0 as! Int)})
        register(Int.self, targetType: Double.self, conversion: {Double($0 as! Int)})

        // Int64

        register(Int64.self, targetType: String.self, conversion: {String($0 as! Int64)})
        register(Int64.self, targetType: Float.self, conversion: {Float($0 as! Int64)})
        register(Int64.self, targetType: Double.self, conversion: {Double($0 as! Int64)})

        // UInt64

        register(UInt64.self, targetType: String.self, conversion: {String($0 as! UInt64)})
        register(UInt64.self, targetType: Float.self, conversion: {Float($0 as! UInt64)})
        register(UInt64.self, targetType: Double.self, conversion: {Double($0 as! UInt64)})

        // Int32

        register(Int32.self, targetType: String.self, conversion: {String($0 as! Int32)})
        register(Int32.self, targetType: Int64.self, conversion: {Int64($0 as! Int32)})
        register(Int32.self, targetType: Float.self, conversion: {Float($0 as! Int32)})
        register(Int32.self, targetType: Double.self, conversion: {Double($0 as! Int32)})

        // UInt32

        register(UInt32.self, targetType: String.self, conversion: {String($0 as! UInt32)})
        register(UInt32.self, targetType: UInt64.self, conversion: {UInt64($0 as! UInt32)})
        register(UInt32.self, targetType: Float.self, conversion: {Float($0 as! UInt32)})
        register(UInt32.self, targetType: Double.self, conversion: {Double($0 as! UInt32)})

        // Int16

        register(Int16.self, targetType: String.self, conversion: {String($0 as! Int16)})
        register(Int16.self, targetType: Int32.self, conversion: {Int32($0 as! Int16)})
        register(Int16.self, targetType: Int64.self, conversion: {Int64($0 as! Int16)})
        register(Int16.self, targetType: Float.self, conversion: {Float($0 as! Int16)})
        register(Int16.self, targetType: Double.self, conversion: {Double($0 as! Int16)})

        // UInt16

        register(UInt16.self, targetType: String.self, conversion: {String($0 as! UInt16)})
        register(UInt16.self, targetType: UInt32.self, conversion: {UInt32($0 as! Int16)})
        register(UInt16.self, targetType: UInt32.self, conversion: {UInt64($0 as! Int16)})
        register(UInt16.self, targetType: Float.self, conversion: {Float($0 as! UInt16)})
        register(UInt16.self, targetType: Double.self, conversion: {Double($0 as! UInt16)})

        // Int8

        register(Int8.self, targetType: String.self, conversion: {String($0 as! Int8)})
        register(Int8.self, targetType: Int16.self, conversion: {Int16($0 as! Int8)})
        register(Int8.self, targetType: Int32.self, conversion: {Int32($0 as! Int8)})
        register(Int8.self, targetType: Int64.self, conversion: {Int64($0 as! Int8)})
        register(Int8.self, targetType: Float.self, conversion: {Float($0 as! Int8)})
        register(Int8.self, targetType: Double.self, conversion: {Double($0 as! Int8)})

        // UInt8

        register(UInt8.self, targetType: String.self, conversion: {String($0 as! UInt8)})
        register(UInt8.self, targetType: UInt16.self, conversion: {UInt16($0 as! UInt8)})
        register(UInt8.self, targetType: UInt32.self, conversion: {UInt32($0 as! UInt8)})
        register(UInt8.self, targetType: UInt64.self, conversion: {UInt64($0 as! UInt8)})
        register(UInt8.self, targetType: Float.self, conversion: {Float($0 as! UInt8)})
        register(UInt8.self, targetType: Double.self, conversion: {Double($0 as! UInt8)})

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
