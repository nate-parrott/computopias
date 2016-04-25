//
//  Firebase+Get.swift
//  Computopias
//
//  Created by Nate Parrott on 4/25/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

extension Firebase {
    func get(callback: (AnyObject -> ())) {
        observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
            callback(snapshot.value)
        }
    }
}
