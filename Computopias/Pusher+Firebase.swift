//
//  Pusher+Firebase.swift
//  Computopias
//
//  Created by Nate Parrott on 3/30/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

class FirebasePusher: Pusher<FDataSnapshot?> {
    init(firebase: FQuery) {
        self.firebase = firebase
        super.init()
        _handle = firebase.observeEventType(.Value, withBlock: { [weak self] (let snapshot) in
            self?.push(snapshot)
        })
    }
    var _handle: UInt!
    let firebase: FQuery
    deinit {
        firebase.removeObserverWithHandle(_handle)
    }
}

extension FQuery {
    var pusher: Pusher<AnyObject> {
        get {
            return FirebasePusher(firebase: self).map({ $0!.value })
        }
    }
    var snapshotPusher: Pusher<FDataSnapshot?> {
        get {
            return FirebasePusher(firebase: self)
        }
    }
}
