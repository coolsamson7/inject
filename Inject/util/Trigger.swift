//
// Created by Andreas Ernst on 20.07.16.
// Copyright (c) 2016 Andreas Ernst. All rights reserved.
//

import Foundation

public protocol TriggerListener {
    func stateChanged(trigger : Trigger) -> Void;
}

public class Trigger {
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

        override func invalidate(recursive : Bool) -> Void  {
            super.invalidate(recursive)

            if recursive {
                for trigger in triggers {
                    trigger.invalidate(recursive);
                }
            }
        }

        func stateChanged(trigger : Trigger) -> Void {
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

        override func invalidate(recursive : Bool) -> Void  {
            super.invalidate(recursive)

            if recursive {
                for trigger in triggers {
                    trigger.invalidate(recursive);
                }
            }
        }

        func stateChanged(trigger : Trigger) -> Void {
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

        func stateChanged(trigger : Trigger) -> Void {
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

    init(state : Bool?) {
        cachedState = state;
    }

    // public

    func not() -> Trigger {
        return Not(trigger: self);
    }

    func and(triggers : Trigger...) -> Trigger {
        return And(triggers: triggers);
    }

    func or(triggers : Trigger...) -> Trigger {
        return Or(triggers: triggers);
    }

    public func addListener(listener : TriggerListener) -> Void {
        listeners.append(listener)
    }

    public func getState() -> Bool {
        if cachedState == nil {
            updateState();
        }

        return cachedState!;
    }

    public func invalidate(recursive : Bool) -> Void  {
        cachedState = nil
    }

    public func revalidate() -> Void {
        invalidate(true); // recursive invalidation

        getState(); // force recompute
    }

    public func remove() -> Void {
        // noop TODO naming
    }

    // abstract

    public func computeState() -> Bool {
        return false;
    }

    // protected

    func setState(newState : Bool) -> Void {
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