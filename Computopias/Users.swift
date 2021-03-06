//
//  Users.swift
//  Computopias
//
//  Created by Nate Parrott on 3/30/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

extension Data {
    static let LoginDidCompleteNotification = "LoginDidCompleteNotification"
    
    #if arch(i386) || arch(x86_64)
    static let ALLOW_FAKE_LOGIN = false // true
    #else
    static let ALLOW_FAKE_LOGIN = false
    #endif
    
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
        return ["name": getName() ?? "", "uid": getUID()!]
    }
    
    static func hashPhoneNumber(n: String) -> String {
        let salt = "igrh0e8whr0e3j4rw0j4" // yeah yeah, insecure, yeah yeah
        return (salt + n).MD5String()
    }
    
    static func logIn(phone: String, name: String, firebaseToken: String, callback: Bool -> ()) {
        firebase.authWithCustomToken(firebaseToken) { (_, let authDataOpt) in
            if authDataOpt != nil {
                self._completeLogin(phone, name: name, callback: callback)
            } else {
                callback(false)
            }
        }
    }
    
    static func fakeLogin(phone: String, name: String, callback: Bool -> ()) {
        firebase.authCreatingUserIfNecessary("fakePhone-" + phone, password: "password") { (let authDataOpt) in
            if authDataOpt != nil {
                self._completeLogin(phone, name: name, callback: callback)
            } else {
                callback(false)
            }
        }
    }
    
    static func _completeLogin(phone: String, name: String, callback: Bool -> ()) {
        NSUserDefaults.standardUserDefaults().setValue(phone, forKey: "Phone")
        Data.setName(name)
        
        let userLocation = self.firebase.childByAppendingPath("users").childByAppendingPath(self.getUID())
        userLocation.childByAppendingPath("phoneHash").setValue(Data.hashPhoneNumber(phone))
        
        let initialHelloCardJson = "{\"card\":{\"cardID\":\"-KH2fxXiXdWopNNWaxvI\",\"date\":1.462498220247923E9,\"hashtag\":\"whatisthis\",\"negativeDate\":-1.462498220247919E9,\"poster\":{\"name\":\"Nate\",\"uid\":\"+17185947958\"}},\"following\":\"+17185947958\",\"negativeDate\":-1.462498220247988E9,\"type\":\"card\"}"
        var initialHelloCard: [String: AnyObject] = try! NSJSONSerialization.JSONObjectWithData(initialHelloCardJson.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as! [String: AnyObject]
        initialHelloCard["negativeDate"] = -NSDate().timeIntervalSince1970
        Data.firebase.childByAppendingPath("inboxes").childByAppendingPath(Data.getUID()!).childByAutoId().setValue(initialHelloCard)
        
        profileFirebase().observeSingleEventOfType(.Value, withBlock: { (let snapshot) in
            if snapshot.value === NSNull() {
                // initialize the default card:
                self.createDefaultProfile(name)
            }
            // post-signup work:
            // follow self:
            Data.setFollowing(Data.getUID()!, following: true, type: .User)
            NSNotificationCenter.defaultCenter().postNotificationName(LoginDidCompleteNotification, object: nil)
            callback(true)
        })
    }
    
    static func profileFirebase() -> Firebase! {
        if let uid = getUID() {
            return firebase.childByAppendingPath("cards").childByAppendingPath(uid)
        }
        return nil
    }
    
    static func userInfoFirebase() -> Firebase! {
        if let uid = getUID() {
            return firebase.childByAppendingPath("users").childByAppendingPath(uid)
        }
        return nil
    }
    
    static func findUserByPhone(phone: String, callback: (FDataSnapshot? -> ())) {
        let hash = hashPhoneNumber(phone.normalizedPhone)
        print("\(hash)")
        // let q = firebase.childByAppendingPath("users").queryEqualToValue(hashPhoneNumber(phone.normalizedPhone), childKey: "phoneHash")
        let q = firebase.childByAppendingPath("users").queryOrderedByChild("phoneHash").queryEqualToValue(hash)
        q.observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
            if snapshot != nil && snapshot.hasChildren() {
                callback((snapshot.children.allObjects.first! as! FDataSnapshot))
            } else {
                callback(nil)
            }
        }
    }
    
    static func createDefaultProfile(name: String) {
        var card = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("DefaultProfile", ofType: "json")!)!, options: []) as! [String: AnyObject]
        card["poster"] = profileJson()
        var items = card["items"] as! [[String: AnyObject]]
        items[0]["text"] = name
        items[1]["chatID"] = NSUUID().UUIDString
        items[2]["counterID"] = NSUUID().UUIDString
        card["items"] = items
        profileFirebase().setValue(card)
    }
    
    static func userJsonForUser(uid: String, callback: [String: AnyObject]? -> ()) {
        Data.firebase.childByAppendingPath("users").childByAppendingPath(uid).childByAppendingPath("name").get { (name) in
            if let n = name as? String {
                callback(["uid": uid, "name": name])
            } else {
                callback(nil)
            }
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
