//
//  Stacktrace.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

/// `Stacktrace` stores s swift stacktrace

public class Stacktrace : CustomStringConvertible {
    // MARK: local classes

    struct Frame : CustomStringConvertible {
        // instance data

        var module : String = ""
        var pointer : String = ""
        var location : String
        var line : String = ""

        // init

        init(line : String) {
            location = line

            func split(str : String) -> [String] {
                var words = [String]()

                str.enumerateSubstringsInRange(str.rangeOfString(str)!, options: .ByWords) { (substring, _, _, _) -> () in
                    words.append(substring!)
                }

                return words
            }

            var elements = split(line);

            module   = elements[1]
            pointer  = elements[2]
            self.line     = elements[elements.count - 1]
            location = _stdlib_demangleName(elements[3])

            if location.containsString(".") {  // <module>.<class>.<function>
                let dot = location.indexOf(".")

                location =  location.substring(from: dot + 1) // remove module

                let brackets = location.indexOf("(")
                if brackets >= 0 {
                    if location[brackets - 1] == "." {
                        // caution with generic functions.... LogManager.Logger.(fatal <A> ( ... ) ...
                        location = location[0 ..< brackets] + split(location.substring(from: brackets))[0]
                    }
                    else {
                        location = location[0 ..< brackets] // strip function signature
                    }
                }
            }

            if elements.count > 5 {
                location += "." + elements[4]
            }
        }

        // implement CustomStringConvertible

        internal var description: String {
            return module + " " + location + " in " + line
        }
    }

    // MARK: instance data

    var frames : [Frame]

    // MARK: init

    public init(frames : [String] = NSThread.callStackSymbols()) {
        self.frames = frames.map({Frame(line: $0)})
    }

    // MARK: implement CustomStringConvertible

    public var description: String {
        let builder = StringBuilder()

        for frame in frames {
            builder.append(frame).append("\n")
        }

        return builder.toString()
    }
}