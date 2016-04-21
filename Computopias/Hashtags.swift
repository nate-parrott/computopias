//
//  Hashtags.swift
//  Computopias
//
//  Created by Nate Parrott on 4/1/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

extension Data {
    static func createOrUpdateHashtag(hashtag: String, cardID: String) {
        let hashtagFirebase = Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag)
        
        hashtagFirebase.childByAppendingPath("cards").childByAppendingPath(cardID).setValue(cardJson(cardID, hashtag: hashtag))
        Data.firebase.childByAppendingPath("all_hashtags").childByAppendingPath(hashtag).childByAppendingPath("hashtag").setValue(hashtag)
        Data.firebase.childByAppendingPath("all_hashtags").childByAppendingPath(hashtag).childByAppendingPath("negativeDate").setValue(-NSDate().timeIntervalSince1970)
        
        // does the hashtag already have an owner?
        hashtagFirebase.childByAppendingPath("owners").observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
            if snapshot.value === NSNull() {
                // no owners; let's become one:
                hashtagFirebase.childByAppendingPath("owners").childByAppendingPath(getUID()!).setValue(profileJson())
            }
        }
    }
    
    static func doesHashtagExist(tag: String, callback: (String, Bool) -> ()) {
        Data.firebase.childByAppendingPath("all_hashtags").childByAppendingPath(tag).observeSingleEventOfType(FEventType.Value) { (let snapshot: FDataSnapshot!) in
            let available = (snapshot.value as? NSNull) != nil
            callback(tag, !available)
        }
    }
}
