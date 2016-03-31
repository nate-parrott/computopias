//
//  Pusher+Firebase.swift
//  Computopias
//
//  Created by Nate Parrott on 3/30/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

class FirebasePusher: Pusher<AnyObject> {
    init(firebase: Firebase) {
        self.firebase = firebase
        super.init()
        _handle = firebase.observeEventType(.Value, withBlock: { [weak self] (let snapshot) in
            self?.push(snapshot.value)
        })
    }
    var _handle: UInt!
    let firebase: Firebase
    deinit {
        firebase.removeObserverWithHandle(_handle)
    }
}

extension Firebase {
    var pusher: FirebasePusher {
        get {
            return FirebasePusher(firebase: self)
        }
    }
}
