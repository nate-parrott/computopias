//
//  Notifications.swift
//  Computopias
//
//  Created by Nate Parrott on 4/25/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

extension Data {
    static var userDisplayName: String {
        get {
            return getName() ?? getPhone() ?? getUID() ?? "???"
        }
    }
    static func notifyLike(emoji: String, cardID: String, hashtag: String) {
        let message = "\(userDisplayName) \(emoji)’d your post in #\(hashtag)."
        let cardURL = Route.Card(hashtag: hashtag, id: cardID).url.absoluteString
        firebase.childByAppendingPath("cards").childByAppendingPath(cardID).childByAppendingPath("poster").childByAppendingPath("uid").get { (let id) in
            if let uid = id as? String {
                Data.sendNotification(message, url: cardURL, toUsers: [uid])
            }
        }
    }
    static func notifyComment(chatID: String, cardID: String, hashtag: String) {
        let message = "\(userDisplayName) commented on a post in #\(hashtag)"
        let messageToOriginalPoster = "\(userDisplayName) commented on your post in #\(hashtag)"
        let cardURL = Route.Card(hashtag: hashtag, id: cardID).url.absoluteString
        var cardPoster: String?
        // TODO: link directly to comments
        
        var notify = Set<String>()
        firebase.childByAppendingPath("chats").childByAppendingPath(chatID).childByAppendingPath("participants").get { (let result) in
            if let keys = (result as? [String: AnyObject])?.keys {
                for key in keys {
                    notify.insert(key)
                }
            }
            firebase.childByAppendingPath("cards").childByAppendingPath(cardID).childByAppendingPath("poster").childByAppendingPath("uid").get { (let id) in
                if let uid = id as? String {
                    cardPoster = uid
                    notify.remove(uid)
                }
                
                Data.sendNotification(message, url: cardURL, toUsers: Array(notify))
                if let id = cardPoster {
                    Data.sendNotification(messageToOriginalPoster, url: cardURL, toUsers: [id])
                }
            }
        }
    }
    static func notifyFollowed(userID: String) {
        let message = "\(userDisplayName) followed you."
        let url = Route.Profile(id: userID).url.absoluteString
        sendNotification(message, url: url, toUsers: [userID])
    }
    static func sendNotification(notif: String, url: String?, toUsers: [String]) {
        var dict: [String: AnyObject] = ["text": notif, "negativeDate": -NSDate().timeIntervalSince1970]
        if let u = url { dict["url"] = u }
        
        let selfID = getUID()
        for uid in toUsers {
            if uid != selfID {
                Data.firebase.childByAppendingPath("notifications").childByAppendingPath(uid).childByAutoId().setValue(dict)
            }
        }
    }
}

class NotificationsSource: NSObject {
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationsSource._updateSubscription), name: Data.LoginDidCompleteNotification, object: nil)
        _updateSubscription()
    }
    
    func _updateSubscription() {
        if let uid = Data.getUID() {
            _subscription = Data.firebase.childByAppendingPath("notifications").childByAppendingPath(uid).queryOrderedByChild("negativeDate").queryLimitedToFirst(50).snapshotPusher.subscribe({ [weak self] (let snapshot: FDataSnapshot?) in
                self?._updateWithNotifications(snapshot?.childDictionaries ?? [])
            })
        } else {
            _subscription = nil
        }
    }
    var _subscription: Subscription?
    
    let notificationDicts = Observable<[[String: AnyObject]]>(val: [])
    let unreadCount = Observable<Int>(val: 0)
    
    func  _updateWithNotifications(notifs: [[String: AnyObject]]) {
        unreadCount.val = notifs.filter({ !($0["read"] as? Bool ?? false) }).count
        notificationDicts.val = notifs
    }
    
    static let Shared = NotificationsSource()
}
