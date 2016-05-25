//
//  ContactsSync.swift
//  Computopias
//
//  Created by Nate Parrott on 3/31/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase
import Contacts

extension Data {
    static let ContactSyncRequestStatusChangedNotification = "ContactSyncRequestStatusChangedNotification"
    
    static func hasRequestedContactSync() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("HasRequestedContactSync") ?? false
    }
    
    static func noThanksNoContactSyncForMe() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasRequestedContactSync")
        NSNotificationCenter.defaultCenter().postNotificationName(ContactSyncRequestStatusChangedNotification, object: nil)
    }
    
    static func doContactsSync(callback: (Bool -> ())) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasRequestedContactSync")
        NSNotificationCenter.defaultCenter().postNotificationName(ContactSyncRequestStatusChangedNotification, object: nil)
        let store = CNContactStore()
        store.requestAccessForEntityType(.Contacts) { (granted, _) in
            if !granted {
                callback(false)
                return
            }
            let fetchReq = CNContactFetchRequest(keysToFetch: [CNContactPhoneNumbersKey])
            do {
                var phoneNumbers = [CNPhoneNumber]()
                let maxPhoneNumbers = 3000
                try store.enumerateContactsWithFetchRequest(fetchReq, usingBlock: { (contact, _) in
                    for phone in contact.phoneNumbers {
                        if let val = phone.value as? CNPhoneNumber where phoneNumbers.count < maxPhoneNumbers {
                            phoneNumbers.append(val)
                        }
                    }
                })
                mainThread() {
                    _contactsSyncWithRemainingContacts(phoneNumbers, callback: callback)
                }
            } catch _ {
                callback(false)
            }
        }
    }
    
    static func _contactsSyncWithRemainingContacts(contacts: [CNPhoneNumber], callback: (Bool -> ())) {
        let batchSize = 10
        var i = 0
        var pendingSearches = 0
        for val in contacts {
            pendingSearches += 1
            Data.findUserByPhone(val.stringValue, callback: { (userSnapshotOpt) in
                if let id = userSnapshotOpt?.key {
                    Data.setFollowing(id, following: true, type: .User)
                }
                pendingSearches -= 1
                if pendingSearches == 0 {
                    if batchSize < contacts.count {
                        _contactsSyncWithRemainingContacts(Array(contacts[batchSize..<contacts.count]), callback: callback)
                    } else {
                        callback(true)
                    }
                }
            })
            
            i += 1
            if i >= batchSize { break }
        }
        
        
        /*mainThread({
            pendingSearches += 1
            Data.findUserByPhone(val.stringValue, callback: { (userSnapshotOpt) in
                if let id = userSnapshotOpt?.key {
                    Data.setFollowing(id, following: true, type: .User)
                }
                pendingSearches -= 1
                if pendingSearches == 0 {
                    callback(true)
                }
            })
        })*/
    }
    
    static func shouldPromptToDoContactSync() -> Bool {
        return !hasRequestedContactSync() && CNContactStore.authorizationStatusForEntityType(.Contacts) != .Denied
    }
}
