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
    - cardJson
  - owners/<uid>/<userJson>
  - info/
    - description

cardJson:
 - date, cardID, negativeDate, likes, negativeLikes, poster
 
/templates/<hashtag>
  - card object

/cards/<cardID>/
  - items/<item>/
    - type
    - more props
  - width
  - height
  - poster: userJson
 
/counters/uuid/<uid>
 
/users/<uid>/
  - name
  - phone (hashed)
  /hashtags/<hashtag> TODO
  /following_users/<uid>
  /posts/ TODO
    - negativeDate
    - cardID
    - hashtag
    - sender: userJson
 
/chats/<id>
    - count
    /messages/<id>
        - text: string
        - sender: userJson
        - date: timestamp

dates are unix timestamps
 
/followers/<target>/<inbox>
/following/<inbox>/<target>

<target> is a hashtag or uid
 
/inboxes/<id>
 - type: "card"
 - negativeDate
 - card: cardJson
 
*/

import Foundation
import Firebase

typealias GridSize = CGSize

struct Data {
    static func getUID() -> String? {
        return firebase.authData?.uid
    }
    
    static let firebase = Firebase(url: "https://computopias.firebaseio.com")
    
    static var lastHomeScreenShownWasFriendsList: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("LastHomeScreenShownWasFriendsList") ?? true
        }
        set(val) {
            NSUserDefaults.standardUserDefaults().setBool(val, forKey: "LastHomeScreenShownWasFriendsList")
        }
    }
        
    static func DeleteCard(id: String) {
        firebase.childByAppendingPath("cards").childByAppendingPath(id).observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
            if let s = snapshot, let dict = s.value as? [String: AnyObject], let hashtag = dict["hashtag"] as? String {
                firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("cards").childByAppendingPath(id).setValue(nil)
            }
            firebase.childByAppendingPath("cards").childByAppendingPath(id).setValue(nil)
        }
    }
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
    var normalizedPhone: String {
        get {
            var nums = componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
            if nums.utf16.count == 10 {
                nums = "1" + nums
            }
            return nums
        }
    }
}

