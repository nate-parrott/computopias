//
//  HashtagCardsViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class HashtagCardsViewController: CardsViewController {
    var hashtag: String!
    
    override func startUpdating() {
        super.startUpdating()
        source = HashtagFeedSource(hashtag: hashtag)
        _cardsSub = source?.cardIDs.subscribe({ [weak self] (let cardIDs) in
            self?._updateCards()
        })
        _updateCards()
    }
    override func stopUpdating() {
        super.stopUpdating()
        source = nil
    }
    var source: HashtagFeedSource?
    var _cardsSub: Subscription?
    func _updateCards() {
        var items = [Item]()
        for id in source!.cardIDs.val {
            if let card = source!.cardsByID[id] {
                if let model = CardItem(dict: card, vc: self) {
                    items.append(model)
                }
            }
        }
        modelItems = items
    }
}
