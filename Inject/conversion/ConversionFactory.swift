//
//  ConversionFactory.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
/// A `ConversionFactory` is used to retrieve conversion functions between different types
public protocol ConversionFactory {
    /// return `true` is a conversion between the specified source- and target-type is registered
    /// - Parameter sourceType: the source type
    /// - Parameter targetType: the target type
    /// - Returns: the boolean value
    func hasConversion(_ sourceType : Any.Type, targetType : Any.Type) -> Bool
    
    /// return  matching conversion between the specified source- and target-type, if registered, or `nil`
    /// - Parameter sourceType: the source type
    /// - Parameter targetType: the target type
    /// - Returns: the matching conversion if found
    func findConversion(_ sourceType : Any.Type, targetType : Any.Type) -> Conversion?
    
    /// return  matching conversion between the specified source- and target-type or throws an exception
    /// - Parameter sourceType: the source type
    /// - Parameter targetType: the target type
    /// - Returns: the matching conversion if found
    func getConversion(_ sourceType : Any.Type, targetType : Any.Type) throws -> Conversion
}
