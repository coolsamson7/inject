//
//  Promise.swift
//  Inject
//
//  Created by Andreas Ernst on 18.07.16.
//  Copyright © 2016 Andreas Ernst. All rights reserved.
//

public enum PromiseState<T>{
    case Pending
    case Resolved(value:T)
    case Rejected(error:ErrorType)

    // convenience funcs

    public var isPending: Bool {
        if case .Pending = self {
            return true
        }
        else {
            return false
        }
    }

    func value() -> T {
        switch self {
            case let .Resolved(value):
                return value
            default:
                precondition(false, "should not happen")
        }
    }
}

public class Promise<T> {
    // MARK: alias

    public typealias ErrorHandler = ErrorType -> Void
    public typealias SuccessHandler = T -> Void

    // internal

    typealias Listener = Promise<T> -> Void

    // MARK: class funcs

    public func when<T, U>(p1: Promise<T>, _ p2: Promise<U>) -> Promise<(T, U)> {
        return when([p1.asVoid(), p2.asVoid()]).then() {
            (p1.state.value(), p2.state.value())
        }
    }

    public func when<T, U, V>(p1: Promise<T>, _ p2: Promise<U>, _ p3: Promise<V>) -> Promise<(T, U, V)> {
        return when([p1.asVoid(), p2.asVoid(), p3.asVoid()]).then() {
            (p1.state.value(), p2.state.value(), p3.state.value())
        }
    }

    private func when(promises: [Promise<Void>]) -> Promise<Void> {
        let masterPromise = Promise<Void>()

        var (total, resolved) = (promises.count, 0)

        for promise in promises {
            promise
            .onSuccess({
                value in

                resolved += 1
                if resolved == total {
                    masterPromise.resolve()
                }

            })
            .onError({
                error in

                masterPromise.reject(error)
            })
        }

        return masterPromise
    }

    // MARK: instance data

    var state     : PromiseState<T>
    var onError   : ErrorHandler?
    var onSuccess : SuccessHandler?
    var listener  : Listener?

    // MARK: init

    init() {
        self.state = .Pending
    }

    // MARK: private

    private func addListener<U>(promise: Promise<U>, _ body: T throws -> U?) {
        listener = {
            result in

            switch result.state {
                case let .Resolved(value):
                    do {
                        if let result = try body(value) { // execute body
                            promise.resolve(result)
                        }
                    }
                    catch {
                        promise.reject(error)
                    }
                case let .Rejected(error):
                    promise.reject(error)

                default:
                   precondition(false, "should not happen")
            }
        }
    }

    private func update(state state: PromiseState<T>) {
        // set state

        self.state = state

        // call handlers

        switch state {
            case let .Resolved(value):
                onSuccess?(value)
            case let .Rejected(error):
                onError?(error)
            default:
                precondition(false, "should not happen")
        }

        // next one please

        if let listener = listener {
            listener(self)
        }

        // clear local state

        onSuccess = nil
        onError   = nil
        listener  = nil
    }

    private func asVoid() -> Promise<Void> {
        return then() {
            _ in return
        }
    }

    // MARK: public funcs

    public func then<U>(body: T throws -> U) -> Promise<U> {
        let promise = Promise<U>()

        addListener(promise, body)

        return promise
    }

    public func then<U>(body: T throws -> Promise<U>) -> Promise<U> {
        let promise = Promise<U>()

        addListener(promise) {
            value -> U? in
            let nextPromise : Promise<U> = try body(value)

            nextPromise.addListener(promise, {$0})

            return nil
        }

        return promise
    }

    // callbacks

    public func onSuccess(handler: SuccessHandler) -> Self {
        onSuccess = handler

        return self
    }

    public func onError(handler: ErrorHandler) -> Self {
        onError = handler

        return self
    }

    // state

    public func reject(error: ErrorType) {
        guard state.isPending else {
            return
        }

        update(state: .Rejected(error: error))
    }

    public func resolve(value: T) {
        guard state.isPending else {
            return
        }

        update(state: .Resolved(value: value))
    }
}