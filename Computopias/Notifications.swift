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
                Data.sendNotification(Notification(message: message, url: cardURL, recipients: [uid]))
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
                Data.sendNotification(Notification(message: message, url: cardURL, recipients: Array(notify)))
                if let id = cardPoster {
                    Data.sendNotification(Notification(message: messageToOriginalPoster, url: cardURL, recipients: [id]))
                }
            }
        }
    }
    static func notifyFollowed(userID: String) {
        let message = "\(userDisplayName) followed you."
        let url = Route.Profile(id: getUID()!).url.absoluteString
        sendNotification(Notification(message: message, url: url, recipients: [userID]))
    }
    struct Notification {
        var message: String
        var url: String?
        var recipients: [String]
        
        func toJson() -> [String: AnyObject] {
            let pushes = recipients.map({ self.pushJsonWithRecipient($0) })
            return ["pushes": pushes]
        }
        
        func pushJsonWithRecipient(recip: String) -> [String: AnyObject] {
            var j = [String: AnyObject]()
            j["text"] = message
            if let u = url { j["link"] = u }
            j["recipient"] = recip
            return j
        }
    }
    static func sendNotification(notification: Notification) {
        var notif = notification
        let selfID = getUID()
        notif.recipients = notif.recipients.filter({ $0 != selfID })
        if notif.recipients.count > 0 {
            var dict: [String: AnyObject] = ["text": notif.message, "negativeDate": -NSDate().timeIntervalSince1970]
            if let u = notif.url { dict["url"] = u }
            
            for uid in notif.recipients {
                Data.firebase.childByAppendingPath("notifications").childByAppendingPath(uid).childByAutoId().setValue(dict)
            }
        }
        
        // send it:
        let url = NSURL(string: "http://localhost:20080/push")!
        let req = NSMutableURLRequest(URL: url)
        req.HTTPMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(notif.toJson(), options: [])
        NSURLSession.sharedSession().dataTaskWithRequest(req).resume()
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
                self?.notificationIDs = snapshot?.children.map({ ($0 as! FDataSnapshot).key }) ?? []
            })
        } else {
            _subscription = nil
        }
    }
    var _subscription: Subscription?
    
    let notificationDicts = Observable<[[String: AnyObject]]>(val: [])
    var notificationIDs = [String]()
    let unreadCount = Observable<Int>(val: 0)
    
    func  _updateWithNotifications(notifs: [[String: AnyObject]]) {
        unreadCount.val = notifs.filter({ !($0["read"] as? Bool ?? false) }).count
        notificationDicts.val = notifs
    }
    
    static let Shared = NotificationsSource()
    
    func markAllAsRead() {
        if let uid = Data.getUID() {
            let notifs = Data.firebase.childByAppendingPath("notifications").childByAppendingPath(uid)
            for id in notificationIDs {
                notifs.childByAppendingPath(id).childByAppendingPath("read").setValue(true)
            }
        }
    }
}
