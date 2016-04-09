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
            addSubview(label)
            label.textAlignment = .Center
            label.textColor = UIColor(white: 0.1, alpha: 0.5)
        }
    }
    
    let cardView = CardView()
    private let label = UILabel()
    var labelText: NSAttributedString? {
        didSet {
            label.attributedText = labelText
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.bounds = CGRectMake(0, 0, CardView.CardSize.width, CardView.CardSize.height)
        cardView.center = bounds.center
        let labelHeight = label.sizeThatFits(CGSizeMake(CardView.CardSize.width, 40)).height
        label.frame = CGRectMake(0, -labelHeight-5, CardView.CardSize.width, labelHeight)
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
                    self?.cardView.importJson(json, callback: {
                        for item in self?.cardView.items ?? [] {
                            item.prepareToPresent()
                        }
                    })
                }
                })
        }
    }
}
