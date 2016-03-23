//
//  LikeCounterCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class LikeCounterCardItemView: CounterCardItemView {
    override func setup() {
        super.setup()
        emoji = "♥︎"
    }
    override func willModifyCount(add: Int) {
        super.willModifyCount(add)
        if let cardID = card?.cardFirebase?.key, let hashtag = card?.hashtag {
            Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath(cardID).childByAppendingPath("likes").setValue(count + add)
            Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath(cardID).childByAppendingPath("negativeLikes").setValue(-(count + add))
        }
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "likes"
        return j
    }
}
