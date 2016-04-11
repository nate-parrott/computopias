//
//  CardFeedStack.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardFeedStack: CardStack {
    override func createCard(model: String) -> UIView {
        return CardViewWrapper()
    }
    
    override func renderCard(model: String, view: UIView) {
        let cv = view as! CardViewWrapper
        if let dict = cardDictForID(model),
            let poster = dict["poster"] as? [String: AnyObject],
            let posterName = poster["name"] as? String,
            // let posterId = poster["uid"] as? String,
            let hashtag = dict["hashtag"] as? String {
            // let hashtag = dict["hashtag"] as! String
            let date = dict["date"] as? Double ?? 0
            cv.card = (model, hashtag)
            
            cv.labelText = createCardLabel(hashtag, posterName: posterName, date: date)
        }
    }
    
    func createCardLabel(hashtag: String, posterName: String, date: Double) -> NSAttributedString {
        let dateString = NSDateFormatter.localizedStringFromDate(NSDate(timeIntervalSince1970: date), dateStyle: .ShortStyle, timeStyle: .ShortStyle)
        return NSAttributedString.smallBoldText(posterName) + NSAttributedString.smallText(" on " + dateString)
    }
    
    override var cardModels: [String] {
        get {
            return cardIDs()
        }
        set(v) {}
    }
    
    func cardIDs() -> [String] {
        return []
    }
    
    func cardDictForID(id: String) -> [String: AnyObject]? {
        return nil
    }
}
