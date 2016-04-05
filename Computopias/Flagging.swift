//
//  Flagging.swift
//  Computopias
//
//  Created by Nate Parrott on 4/5/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

class PersistentObject<T:NSCoding> {
    init(name: String) {
        let dir = (NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true).first! as NSString).stringByAppendingPathComponent("PersistentObjects")
        if !NSFileManager.defaultManager().fileExistsAtPath(dir) {
            try! NSFileManager.defaultManager().createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
        }
        path = (dir as NSString).stringByAppendingPathComponent(name)
    }
    let path: String
    var _loadedFromCache = false
    var _cache: T?
    var value: T? {
        get {
            if !_loadedFromCache {
                if NSFileManager.defaultManager().fileExistsAtPath(path) {
                    _cache = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? T
                }
                _loadedFromCache = true
            }
            return _cache
        }
        set(value) {
            _cache = value
            if let v = value {
                NSKeyedArchiver.archiveRootObject(v, toFile: path)
            } else if NSFileManager.defaultManager().fileExistsAtPath(path) {
                _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
            }
        }
    }
}

extension Data {
    static let blockedUserIDs = PersistentObject<NSSet>(name: "BlockedUserIDs")
    // static let blockedCardIDs = PersistentObject<NSSet>(name: "BlockedCardIDs")
    static func flagItemForReview(url: String, additionalInfo: String) {
        Data.firebase.childByAppendingPath("flagged").childByAutoId().setValue(["url": url, "additionalInfo": additionalInfo])
    }
    static let BlockedUsersChangedNotification = "BlockedUsersChangedNotification"
    static func blockUser(user: String) {
        if user == Data.getUID() { return }
        if blockedUserIDs.value == nil { blockedUserIDs.value = NSMutableSet() }
        let set = (blockedUserIDs.value ?? NSSet()).mutableCopy() as! NSMutableSet
        set.addObject(user)
        blockedUserIDs.value = set
        NSNotificationCenter.defaultCenter().postNotificationName(BlockedUsersChangedNotification, object: nil)
    }
    static func userIsBlocked(uid: String) -> Bool {
        if let set = blockedUserIDs.value {
            return set.containsObject(uid)
        } else {
            return false
        }
    }
}
