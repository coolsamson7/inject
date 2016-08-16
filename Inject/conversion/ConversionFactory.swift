//
//  ConversionFactory.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//
public protocol ConversionFactory {
    func hasConversion(sourceType : Any.Type, targetType : Any.Type) -> Bool
    
    func findConversion(sourceType : Any.Type, targetType : Any.Type) -> Conversion?
    
    func getConversion(sourceType : Any.Type, targetType : Any.Type) throws -> Conversion
}