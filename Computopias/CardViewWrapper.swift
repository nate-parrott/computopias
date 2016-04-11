//
//  CardViewWrapper.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class CardViewWrapper: UIView {
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if newWindow != nil {
            _subscribeToCardData()
        } else {
            _cardDataSub = nil
        }
        if cardView.view.superview == nil {
            addSubview(cardView.view)
            layer.addSublayer(label.layer)
        }
    }
    
    let cardView = CardView()
    private let label = ASTextNode()
    var labelText: NSAttributedString? {
        didSet {
            let mText = (labelText?.mutableCopy() ?? NSMutableAttributedString()) as! NSMutableAttributedString
            let para = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            para.alignment = .Center
            mText.addAttribute(NSParagraphStyleAttributeName, value: para, range: NSMakeRange(0, mText.length))
            mText.addAttribute(NSForegroundColorAttributeName, value: UIColor(white: 0.1, alpha: 0.5), range: NSMakeRange(0, mText.length))
            label.attributedString = mText
            backgroundThread { 
                let height = self.label.measure(CGSizeMake(CardView.CardSize.width, 50)).height
                self.label.frame = CGRectMake(0, -height - 5, CardView.CardSize.width, height)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.bounds = CGRectMake(0, 0, CardView.CardSize.width, CardView.CardSize.height)
        cardView.position = bounds.center
    }
    
    var card: (id: String, hashtag: String?)? {
        didSet {
            if let (id, hashtag) = card {
                let cardFirebase = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id)
                cardView.cardFirebase = cardFirebase
                cardView.hashtag = hashtag
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
