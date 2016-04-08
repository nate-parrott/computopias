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
        if let dict = cardDictForID(model) {
            let hashtag = dict["hashtag"] as! String
            cv.card = (model, hashtag)
        }
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
