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
    
    static func logIn(phone: String, firebaseToken: String, callback: Bool -> ()) {
        firebase.authWithCustomToken(firebaseToken) { (_, let authDataOpt) in
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
                    // post-signup work:
                    // follow self:
                    Data.setFollowing(Data.getUID()!, following: true, isUser: true)
                    NSNotificationCenter.defaultCenter().postNotificationName(LoginDidCompleteNotification, object: nil)
                    callback(true)
                })
            } else {
                callback(false)
            }
        }
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
