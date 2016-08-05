//
//  ArrayOf
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public class ArrayOf<T : Equatable> : SequenceType {
    // instance data
    
    private var values : [T]; // cannot put an array in a map!
    
    public var count : Int {
        get {
            return values.count
        }
    }
    
    // init
    
    init(values : T...) {
        self.values = values
    }
    
    // subscript
    
    public subscript(index: Int) -> T {
        get {
            return values[index]
        }
    }
    
    // SequenceType
    
    public func generate() -> IndexingGenerator<[T]> {
        return values.generate()
    }
    
    // func

    public func contains(value : T) -> Bool {
        return values.contains({$0 == value})
    }
    
    public func append(value : T) -> Void {
        values.append(value)
    }
}