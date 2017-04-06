//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation


func ==(lhs: Key, rhs: Key) -> Bool {
    return lhs.clazz == rhs.clazz
}

class Key : Hashable {
    var clazz : AnyClass;

    init(clazz : AnyClass) {
        self.clazz = clazz;
    }

    var hashValue : Int {
        get {
            return clazz.description().hashValue
        }
    }
}

open class CPLRegistry<T> {
    // instance data

    var registry : [Key:T] = [Key:T]();
    var cache : [Key:T]? = nil;

    // methods

    func register(_ clazz: AnyClass, element : T) {
        registry[Key(clazz: clazz)] = element;

        clearCache();
    }

    func get(_ clazz : AnyClass) -> T? {
        if cache == nil {
            cache = [Key:T]();

            // add registered elements

            for (key, value)in registry {
                cache![key] = value;
            }
        }

        if let value = cache![Key(clazz: clazz)] {
            return value;
        }

        // miss...darn

        var classes : [AnyClass] = [AnyClass]();
        var objects : [AnyObject] = [AnyObject]();


        var cl : AnyClass? = clazz;
        classes.append(cl!); objects.append(cl!);

        while cl!.superclass() != nil {
            classes.append(cl!.superclass()!);objects.append(cl!.superclass()!);

            cl = cl!.superclass();
        }

        CPLSorter(classes: classes, objects: &objects)

        // most to least!

        for i in 0..<objects.count {
            let key = Key(clazz: objects[i] as! AnyClass)
            if let value = registry[key] {
                cache![key] = value;

                return value;
            }
        }

        // done

        return nil;
    }

    // internal

    func clearCache() -> Void {
        cache = nil;
    }
}

// CPLSorter

class CPLSorter {
    // local classes

    class ClassNode {
        var index : Int = 0;
        var clazz : AnyClass!;
        var next : [ClassNode] = [ClassNode]();
        var inDegree : Int = 0;
        var linked : Bool = false;

        // constructor

        init(clazz : AnyClass) {
            self.clazz = clazz;
        }

        // methods

        func link(_ node : ClassNode) -> Void {
            next.append(node);

            node.inDegree += 1;
        }
    }

    // instance data

    var classes : [String:ClassNode] = [String:ClassNode]();

    // private

    func findNode(_ clazz : AnyClass) -> ClassNode {
        if let node = classes[clazz.description()] {
            return node;
        }
        else {
            let node = ClassNode(clazz: clazz);

            classes[clazz.description()] = node;

            return node;
        }
    }

    // constructor

    init(classes : [AnyClass], objects : inout [AnyObject]) {
        // add classes

        for clazz in classes {
            findNode(clazz);
        }

        // link nodes

        for clazz in classes {
            // traverse interfaces

            var next = [ClassNode]();

            next.append(findNode(clazz));

            while !next.isEmpty {
                let cn = next.remove(at: 0);

                if cn.linked {
                    continue;
                }

                // superclasses

                if let superClass = cn.clazz.superclass() {
                    let node = findNode(superClass);

                    node.link(cn);

                    next.append(node);
                } // if

                /* interfaces

                 if (cn.clazz.isInterface() && cn.clazz.getInterfaces().length == 0) {
                 ClassNode classNode = findNode(Object.class);

                 next.push(classNode);

                 classNode.link(cn);
                 }

                 for (Class interfaceClass : cn.clazz.getInterfaces()) {
                 ClassNode classNode = findNode(interfaceClass);

                 next.push(classNode);

                 classNode.link(cn);
                 } // for
                 */

                cn.linked = true;
            } // while
        } // for

        // initialize stack

        var queue = [ClassNode]();
        for (_, classNode) in self.classes {
            if classNode.inDegree == 0 {
                queue.append(classNode);
            }
        }

        // number nodes

        var i = 0;
        while !queue.isEmpty {
            let classNode = queue.remove(at: 0);

            classNode.index = i;

            i += 1;

            // next

            for next in classNode.next {
                next.inDegree -= 1
                if (next.inDegree == 0) {
                    queue.append(next);
                }
            }
        } // while

        // sort

        class ObjectAndIndex {
            var object : AnyObject;
            var index : Int;

            init(object: AnyObject, index : Int) {
                self.object = object;
                self.index = index;
            }
        }


        var sortedObjects = [ObjectAndIndex]();
        var index = 0;
        for object in objects {
            sortedObjects.append(ObjectAndIndex(object: object, index: index))
            index += 1;
        }

        sortedObjects.sort(by: {findNode(classes[$0.index]).index > findNode(classes[$1.index]).index});

        //print(sortedObjects);

        for i in 0..<objects.count {
            objects[i] = sortedObjects[i].object;
        }
    } // while
}
