//
//  Data.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

/*
FIREBASE STRUCTURE

/all_hashtags/<hashtag>
  - negativeDate
  - hashtag

/hashtags/<hashtag>/
  - cards/<card>
    -date, cardID, negativeDate, likes, negativeLikes

/templates/<hashtag>
  - card object

/cards/<cardID>/
  - items/<item>/
    - type
    - more props
  - width
  - height

/counters/uuid/<uid>

dates are unix timestamps

*/

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
    static func getPhone() -> String? {
        return NSUserDefaults.standardUserDefaults().valueForKey("Phone") as? String
    }
    static func setPhone(phone: String) {
        NSUserDefaults.standardUserDefaults().setValue(phone, forKey: "Phone")
    }
    static func profileJson() -> [String: AnyObject] {
        return ["name": getName() ?? "", "bio": getBio() ?? "", "uid": getUID()]
    }
    static let firebase = Firebase(url: "https://computopias.firebaseio.com")
}

extension FDataSnapshot {
    var childDictionaries: [[String: AnyObject]] {
        var childDicts = [[String: AnyObject]]()
        for child in children {
            if let c = child as? FDataSnapshot, let d = c.value as? [String: AnyObject] {
                childDicts.append(d)
            }
        }
        return childDicts
    }
}

extension String {
    private static let _allowedCharactersForFirebase = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    var sanitizedForFirebase: String {
        get {
            return componentsSeparatedByCharactersInSet(String._allowedCharactersForFirebase.invertedSet).joinWithSeparator("")
        }
    }
}

