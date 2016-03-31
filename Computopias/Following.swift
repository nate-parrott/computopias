//
//  Following.swift
//  Computopias
//
//  Created by Nate Parrott on 3/30/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

extension Data {
    static func isFollowingItem(item: String) -> Pusher<Bool> {
        return FirebasePusher(firebase: firebase.childByAppendingPath("followers").childByAppendingPath(item).childByAppendingPath(getUID())).map({ (let value) -> Bool in
            return value as? Bool ?? false
        })
    }
    
    static func setFollowing(item: String, following: Bool, isUser: Bool) {
        firebase.childByAppendingPath("followers").childByAppendingPath(item).childByAppendingPath(getUID()).setValue(following ? true : nil)
        firebase.childByAppendingPath("following").childByAppendingPath(getUID()).childByAppendingPath(item).setValue(following ? true : nil)
        if isUser {
            userInfoFirebase().childByAppendingPath("following_users").childByAppendingPath(item).setValue(following ? true : nil)
        }
    }
    
    static func broadcastToFollowers(ofItem: String, data: [String: AnyObject]) {
        // `data` dict should include `type` field
        var d = data
        d["negativeDate"] = -NSDate().timeIntervalSince1970
        // fetch followers:
        firebase.childByAppendingPath("followers").childByAppendingPath(ofItem).observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
            for child in snapshot.children {
                let inboxID = (child as! FDataSnapshot).key
                firebase.childByAppendingPath("inboxes").childByAppendingPath(inboxID).childByAutoId().setValue(d)
            }
        }
    }
    
    static func broadcastCardUpdate(cardID: String, hashtag: String) {
        let data: [String: AnyObject] = ["type": "card", "card": cardJson(cardID, hashtag: hashtag)]
        broadcastToFollowers(getUID(), data: data)
        broadcastToFollowers(hashtag, data: data)
    }
    
    static func friendFeed() -> Pusher<[String]> {
        return userInfoFirebase().childByAppendingPath("following_users").pusher.map({ (let data) -> [String] in
            if let dict = data as? [String: AnyObject] {
                return Array(dict.keys)
            } else {
                return []
            }
        })
    }
}
