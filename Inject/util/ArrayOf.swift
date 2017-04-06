//
//  ArrayOf
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

open class ArrayOf<T : Equatable> : Sequence {
    // MARK: instance data
    
    fileprivate var values : [T]; // cannot put an array in a map!
    
    open var count : Int {
        get {
            return values.count
        }
    }
    
    // init
    
    public init(values : T...) {
        self.values = values
    }
    
    // subscript
    
    open subscript(index: Int) -> T {
        get {
            return values[index]
        }
    }
    
    // SequenceType
    
    open func makeIterator() -> IndexingIterator<[T]> {
        return values.makeIterator()
    }
    
    // func

    open func contains(_ value : T) -> Bool {
        return values.contains(where: {$0 == value})
    }
    
    open func append(_ value : T) -> Void {
        values.append(value)
    }
}
