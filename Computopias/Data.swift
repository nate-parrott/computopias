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
    -date, cardID, negativeDate, likes, negativeLikes, poster

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
  /following/<uid>
  /hashtags/<hashtag>
  /posts/
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

*/

import Foundation
import Firebase

typealias GridSize = CGSize

struct Data {
    static func getUID() -> String! {
        return firebase.authData?.uid
    }
    static func profileFirebase() -> Firebase! {
        if let uid = getUID() {
            return firebase.childByAppendingPath("cards").childByAppendingPath(uid)
        }
        return nil
    }
    
    static func getName() -> String? {
        return NSUserDefaults.standardUserDefaults().valueForKey("Name") as? String
    }
    
    static func setName(name: String) {
        NSUserDefaults.standardUserDefaults().setValue(name, forKey: "Name")
        let userLocation = self.firebase.childByAppendingPath("users").childByAppendingPath(self.getUID())
        userLocation.childByAppendingPath("name").setValue(name)
    }
    
    static func getPhone() -> String? {
        return NSUserDefaults.standardUserDefaults().valueForKey("Phone") as? String
    }
    static func profileJson() -> [String: AnyObject] {
        return ["name": getName() ?? "", "uid": getUID()]
    }
    
    static let firebase = Firebase(url: "https://computopias.firebaseio.com")
    
    static func hashPhoneNumber(n: String) -> String {
        let salt = "igrh0e8whr0e3j4rw0j4" // yeah yeah, insecure, yeah yeah
        return (salt + n).MD5String()
    }
    
    static func logIn(phone: String, callback: Bool -> ()) {
        firebase.authCreatingUserIfNecessary(phone, password: "password") { (let authDataOpt) in
            if authDataOpt != nil {
                NSUserDefaults.standardUserDefaults().setValue(phone, forKey: "Phone")
                
                let userLocation = self.firebase.childByAppendingPath("users").childByAppendingPath(self.getUID())
                userLocation.childByAppendingPath("phoneHash").setValue(Data.hashPhoneNumber(phone))
                
                profileFirebase().observeSingleEventOfType(.Value, withBlock: { (let snapshot) in
                    if snapshot.value === NSNull() {
                        // initialize the default card:
                        let defaultCard = ["width": CardView.CardSize.width, "height": CardView.CardSize.height, "items": [], "hashtag": "profiles", "poster": profileJson()]
                        profileFirebase().setValue(defaultCard)
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName(LoginDidCompleteNotification, object: nil)
                    callback(true)
                })
            } else {
                callback(false)
            }
        }
    }
    
    static var lastHomeScreenShownWasFriendsList: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("LastHomeScreenShownWasFriendsList") ?? true
        }
        set(val) {
            NSUserDefaults.standardUserDefaults().setBool(val, forKey: "LastHomeScreenShownWasFriendsList")
        }
    }
    
    static let LoginDidCompleteNotification = "LoginDidCompleteNotification"
    
    static func DeleteCard(id: String) {
        firebase.childByAppendingPath("cards").childByAppendingPath(id).observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
            if let s = snapshot, let dict = s.value as? [String: AnyObject], let hashtag = dict["hashtag"] as? String {
                firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath(id).setValue(nil)
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
}

extension Firebase {
    func authCreatingUserIfNecessary(username: String, password: String, callback: FAuthData! -> ()) {
        let email = username + "@nateparrott.com"
        authUser(email, password: password) { (_, let authData) in
            if authData != nil {
                callback(authData)
            } else {
                self.createUser(email, password: password, withCompletionBlock: { (_) in
                    self.authUser(email, password: password, withCompletionBlock: { (_, let authData) in
                        callback(authData)
                    })
                })
            }
        }
    }
}

