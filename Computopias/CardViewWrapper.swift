//
//  CardViewWrapper.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardViewWrapper: UIView {
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if newWindow != nil {
            _subscribeToCardData()
        } else {
            _cardDataSub = nil
        }
        if cardView.superview == nil {
            addSubview(cardView)
        }
    }
    
    let cardView = CardView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.bounds = CGRectMake(0, 0, CardView.CardSize.width, CardView.CardSize.height)
        cardView.center = bounds.center
    }
    
    var card: (id: String, hashtag: String?)? {
        didSet {
            if let (id, hashtag) = card {
                let cardFirebase = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id)
                cardView.cardFirebase = cardFirebase
                cardView.hashtag = hashtag
                cardView.backgroundImageView.image = Appearance.gradientForHashtag(hashtag ?? "", cardID: id)
                if window != nil {
                    _subscribeToCardData()
                }
            }
        }
    }
    var _cardDataSub: Subscription?
    
    func _subscribeToCardData() {
        if let cardFirebase = cardView.cardFirebase {
            _cardDataSub = cardFirebase.pusher.subscribe({ [weak self] (let data) in
                if let json = data as? [String: AnyObject] {
                    self?.cardView.importJson(json)
                    for item in self?.cardView.items ?? [] {
                        item.prepareToPresent()
                    }
                }
                })
        }
    }
}
