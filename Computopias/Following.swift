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
        return firebase.childByAppendingPath("followers").childByAppendingPath(item).childByAppendingPath(getUID()).pusher.map({ (let value) -> Bool in
            return value as? Bool ?? false
        })
    }
    
    enum FollowType {
        case User
        case Hashtag
    }
    
    static func setFollowing(item: String, following: Bool, type: FollowType) {
        firebase.childByAppendingPath("followers").childByAppendingPath(item).childByAppendingPath(getUID()).setValue(following ? true : nil)
        firebase.childByAppendingPath("following").childByAppendingPath(getUID()).childByAppendingPath(item).setValue(following ? true : nil)
        switch type {
        case .Hashtag:
            userInfoFirebase().childByAppendingPath("following_hashtags").childByAppendingPath(item).setValue(following ? true : nil)
        case .User:
            userInfoFirebase().childByAppendingPath("following_users").childByAppendingPath(item).setValue(following ? true : nil)
            if item != getUID() && following {
                notifyFollowed(item)
            }
        }
    }
    
    static func broadcastToFollowers(ofItem: String, data: [String: AnyObject]) {
        // `data` dict should include `type` field
        var d = data
        d["negativeDate"] = -NSDate().timeIntervalSince1970
        d["following"] = ofItem
        if ofItem == "all" {
            Data.firebase.childByAppendingPath("inboxes").childByAppendingPath("all").childByAutoId().setValue(d)
        } else {
            // fetch followers:
            firebase.childByAppendingPath("followers").childByAppendingPath(ofItem).observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
                for child in snapshot.children {
                    let inboxID = (child as! FDataSnapshot).key
                    firebase.childByAppendingPath("inboxes").childByAppendingPath(inboxID).childByAutoId().setValue(d)
                }
            }
        }
        firebase.childByAppendingPath("outboxes").childByAppendingPath(ofItem).childByAutoId().setValue(d)
    }
    
    static func broadcastCardUpdate(cardID: String, hashtag: String) {
        let data: [String: AnyObject] = ["type": "card", "card": cardJson(cardID, hashtag: hashtag)]
        broadcastToFollowers(getUID()!, data: data)
        broadcastToFollowers(hashtag, data: data)
        broadcastToFollowers("all", data: data)
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
