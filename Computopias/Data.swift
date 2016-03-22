//
//  Data.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

typealias Card = Firebase

extension Card {
    
}

typealias Item = Firebase

typealias Poster = Firebase


typealias GridSize = CGSize

struct Data {
    static func getUID() -> String {
        let key = "UID"
        if (NSUserDefaults.standardUserDefaults().valueForKey(key) as? String) == nil {
            NSUserDefaults.standardUserDefaults().setValue(NSUUID().UUIDString, forKey: key)
        }
        return NSUserDefaults.standardUserDefaults().valueForKey(key) as! String
    }
    static func getName() -> String? {
        return NSUserDefaults.standardUserDefaults().valueForKey("ProfileName") as? String
    }
    static func setName(name: String) {
        // TODO: set name in firebase
        NSUserDefaults.standardUserDefaults().setValue(name, forKey: "ProfileName")
    }
    static func getBio() -> String? {
        return NSUserDefaults.standardUserDefaults().valueForKey("ProfileBio") as? String
    }
    static func setBio(bio: String) {
        // TODO: set bio in firebase
        NSUserDefaults.standardUserDefaults().setValue(bio, forKey: "ProfileBio")
    }
    static func profileJson() -> [String: AnyObject] {
        return ["name": getName() ?? "", "bio": getBio() ?? "", "uid": getUID()]
    }
}
