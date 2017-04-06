//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public protocol TriggerListener {
    func stateChanged(_ trigger : Trigger) -> Void;
}

open class Trigger {
    // local classes

    // Trigger

    class Or : Trigger, TriggerListener {
        // instance data

        var  triggers : [Trigger];

        // init

        init(triggers : [Trigger]) {
            self.triggers = triggers;

            super.init(state: nil);

            for trigger in triggers {
                trigger.addListener(self);
            }

            updateState();
        }

        // override

        override func remove() -> Void {
            for trigger in triggers {
                trigger.remove();
            }
        }

        override func invalidate(_ recursive : Bool) -> Void  {
            super.invalidate(recursive)

            if recursive {
                for trigger in triggers {
                    trigger.invalidate(recursive);
                }
            }
        }

        func stateChanged(_ trigger : Trigger) -> Void {
            updateState();
        }

        override func computeState() -> Bool {
            for trigger in triggers {
                if trigger.getState() {
                    return true
                }
            }

            return false
        }
    }

    class And : Trigger, TriggerListener {
        // instance data

        var  triggers : [Trigger];

        // init

        init(triggers : [Trigger]) {
            self.triggers = triggers;

            super.init(state: nil);

            for trigger in triggers {
                trigger.addListener(self);
            }

            updateState();
        }

        // override

        override func remove() -> Void {
            for trigger in triggers {
                trigger.remove();
            }
        }

        override func invalidate(_ recursive : Bool) -> Void  {
            super.invalidate(recursive)

            if recursive {
                for trigger in triggers {
                    trigger.invalidate(recursive);
                }
            }
        }

        func stateChanged(_ trigger : Trigger) -> Void {
            updateState();
        }

        override func computeState() -> Bool {
            for trigger in triggers {
                if !trigger.getState() {
                    return false
                }
            }

            return true
        }
    }

    class Not : Trigger, TriggerListener {
        // instance data

        var trigger : Trigger;

        // init

        init(trigger : Trigger) {
            self.trigger = trigger;

            super.init(state: !trigger.getState());


            trigger.addListener(self);
        }

        // override

        func stateChanged(_ trigger : Trigger) -> Void {
            updateState();
        }

        override func computeState() -> Bool {
            return !trigger.getState();
        }
    }

    // class data

    static var firing : Trigger? = nil
    static var silent = false

    // instance data

    var context : AnyObject? = nil;
    var cachedState : Bool?;
    var listeners : [TriggerListener] = [TriggerListener]();

    // init

    public init(state : Bool?) {
        cachedState = state;
    }

    // public

    func not() -> Trigger {
        return Not(trigger: self);
    }

    func and(_ triggers : Trigger...) -> Trigger {
        return And(triggers: triggers);
    }

    func or(_ triggers : Trigger...) -> Trigger {
        return Or(triggers: triggers);
    }

    open func addListener(_ listener : TriggerListener) -> Void {
        listeners.append(listener)
    }

    open func getState() -> Bool {
        if cachedState == nil {
            updateState();
        }

        return cachedState!;
    }

    open func invalidate(_ recursive : Bool) -> Void  {
        cachedState = nil
    }

    open func revalidate() -> Void {
        invalidate(true); // recursive invalidation

        getState(); // force recompute
    }

    open func remove() -> Void {
        // noop TODO naming
    }

    // abstract

    open func computeState() -> Bool {
        return false;
    }

    // protected

    func setState(_ newState : Bool) -> Void {
        if (newState != cachedState) {
            cachedState = newState

            if (Trigger.firing == nil) {
                Trigger.firing = self

                fireListeners()

                Trigger.firing = nil
            }
            else {
                fireListeners()
            }
        }
    }

    func updateState() -> Void  {
        setState(computeState());
    }

    func isValid() -> Bool {
        return cachedState != nil; // maybe change to a special constant?
    }

    func isInvalid() -> Bool {
        return !isValid();
    }

    func fireListeners() -> Void {
        for listener in listeners {
            listener.stateChanged(self);
        }
    }
}
