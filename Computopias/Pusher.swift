//
//  Pusher.swift
//  ptrptr
//
//  Created by Nate Parrott on 1/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class Pusher<T> {
    typealias Callback = T -> ()
    
    var _lastSubscriptionId = 0
    var _subscriptionsById = [Int: Callback]()
    
    func subscribe(callback: Callback) -> Subscription {
        let id = _lastSubscriptionId
        _lastSubscriptionId += 1
        _subscriptionsById[id] = callback
        let sub = Subscription()
        sub._onDispose = {
            self._subscriptionsById.removeValueForKey(id)
        }
        return sub
    }
    
    func push(data: T) {
        for cb in Array(_subscriptionsById.values) {
            cb(data)
        }
    }
    
    var subscriptions = [Subscription]() // for your convenience
    
    class func PushLatest(pushers: [Pusher<T>]) -> Pusher<[T]> {
        var latest = [T?]()
        for _ in 0..<pushers.count { latest.append(nil) }
        let result = Pusher<[T]>()
        for (pusher, i) in zip(pushers, 0..<pushers.count) {
            let sub = pusher.subscribe({ (let x) -> () in
                latest[i] = x
                let arrived = latest.filter({ $0 != nil }).map({ $0! })
                if arrived.count == latest.count {
                    result.push(arrived)
                }
            })
            result.subscriptions.append(sub)
        }
        return result
    }
    
    class func PushLatestImmediately(pushers: [Pusher<T>]) -> Pusher<[T?]> {
        var latest = [T?]()
        for _ in 0..<pushers.count { latest.append(nil) }
        let result = Pusher<[T?]>()
        for (pusher, i) in zip(pushers, 0..<pushers.count) {
            let sub = pusher.subscribe({ (let x) -> () in
                latest[i] = x
                result.push(latest)
            })
            result.subscriptions.append(sub)
        }
        return result
    }
    
    func map<T2>(fn: T -> T2) -> Pusher<T2> {
        let result = Pusher<T2>()
        let sub = subscribe { (let x) -> () in
            result.push(fn(x))
        }
        result.subscriptions.append(sub)
        return result
    }
    
    func filter(fn: T -> Bool) -> Pusher<T> {
        let result = Pusher<T>()
        let sub = subscribe { (let x) -> () in
            if fn(x) {
                result.push(x)
            }
        }
        result.subscriptions.append(sub)
        return result
    }
}

class Subscription {
    var _onDispose: (() -> ())!
    deinit {
        _onDispose()
    }
}

class Observable<T>: Pusher<T> {
    init(val: T) {
        self.val = val
    }
    var val: T {
        didSet {
            push(val)
        }
    }
}

func Observe2<T1,T2>(first: Observable<T1>, second: Observable<T2>) -> Observable<(T1,T2)> {
    let result = Observable<(T1,T2)>(val: (first.val, second.val))
    first.subscribe { (let val) -> () in
        result.val = (val, result.val.1)
    }
    second.subscribe { (let val) -> () in
        result.val = (result.val.0, val)
    }
    return result
}

class _PusherForNotificationTarget: NSObject {
    func _receive(notif: NSNotification) {
        pusher?.push(notif)
    }
    weak var pusher: Pusher<NSNotification>!
}

class PusherForNotification: Pusher<NSNotification> {
    init(name: String, object: AnyObject?) {
        _target = _PusherForNotificationTarget()
        super.init()
        _target.pusher = self
        NSNotificationCenter.defaultCenter().addObserver(_target, selector: #selector(_PusherForNotificationTarget._receive(_:)), name: name, object: object)
    }
    let _target: _PusherForNotificationTarget
}
