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
    static func hasRequestedContactSync() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("HasRequestedContactSync") ?? false
    }
    
    static func doContactsSync(callback: (Bool -> ())) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasRequestedContactSync")
        let store = CNContactStore()
        store.requestAccessForEntityType(.Contacts) { (granted, _) in
            if !granted {
                callback(false)
                return
            }
            let fetchReq = CNContactFetchRequest(keysToFetch: [CNContactPhoneNumbersKey])
            do {
                var pendingSearches = 0
                try store.enumerateContactsWithFetchRequest(fetchReq, usingBlock: { (contact, _) in
                    for phone in contact.phoneNumbers {
                        if let val = phone.value as? CNPhoneNumber {
                            mainThread({
                                pendingSearches += 1
                                Data.findUserByPhone(val.stringValue, callback: { (userSnapshotOpt) in
                                    if let id = userSnapshotOpt?.key {
                                        Data.setFollowing(id, following: true, isUser: true)
                                    }
                                    pendingSearches -= 1
                                    if pendingSearches == 0 {
                                        callback(true)
                                    }
                                })
                            })
                            
                        }
                    }
                })
                mainThread({ 
                    if pendingSearches == 0 {
                        callback(true)
                    }
                })
            } catch _ {
                callback(false)
            }
        }
    }
    
    static func shouldPromptToDoContactSync() -> Bool {
        return !hasRequestedContactSync() && CNContactStore.authorizationStatusForEntityType(.Contacts) != .Denied
    }
}
