//
//  SingleCardStack.swift
//  Computopias
//
//  Created by Nate Parrott on 4/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class SingleCardStack: CardFeedStack {
    init(id: String, hashtag: String) {
        _cardID = id
        super.init()
        // load the card dict:
        _sub = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id).pusher.subscribe({ [weak self] (let data) in
            self?._cardDict = data as? [String: AnyObject]
        })
    }
    
    let _cardID: String
    var _sub: Subscription?
    
    var _cardDict: [String: AnyObject]?
    
    override func cardIDs() -> [String] {
        return _cardDict != nil ? [_cardID] : []
    }
    
    override func cardDictForID(id: String) -> [String : AnyObject]? {
        return _cardDict
    }
    
    override func createCardLabel(hashtag: String, posterName: String, date: Double) -> NSAttributedString {
        return NSAttributedString.smallText(posterName + " in ") + NSAttributedString.smallBoldText(hashtag)
    }
}
