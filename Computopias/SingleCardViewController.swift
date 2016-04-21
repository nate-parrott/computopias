//
//  SingleCardViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SingleCardViewController: CardsViewController {
    var cardID: String!
    var hashtag: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "#" + hashtag
        _cardDictSub = Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("cards").childByAppendingPath(cardID).pusher.subscribe({ [weak self] (let data) in
            self?.cardDict = data as? [String: AnyObject]
        })
    }
    
    var _cardDictSub: Subscription?
    var cardDict: [String: AnyObject]? {
        didSet {
            if let dict = cardDict, let item = CardItem(dict: dict, vc: self) {
                modelItems = [item]
            }
        }
    }
}
