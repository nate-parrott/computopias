//
//  CardFeedCells.swift
//  Computopias
//
//  Created by Nate Parrott on 4/1/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class CardCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(cardView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if newWindow != nil {
            _subscribeToCardData()
        } else {
            _cardDataSub = nil
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

class TextCell: UICollectionViewCell {
    let label = UILabel()
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if label.superview == nil {
            contentView.addSubview(label)
            label.textAlignment = NSTextAlignment.Center
            label.textColor = UIColor.blackColor()
            label.alpha = 0.8
            label.numberOfLines = 0
            let tapRec = UITapGestureRecognizer(target: self, action: #selector(TextCell._tapped))
            addGestureRecognizer(tapRec)
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRectMake((bounds.size.width - CardView.CardSize.width)/2, 0, CardView.CardSize.width, bounds.size.height)
    }
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return super.pointInside(point, withEvent: event) || CGRectContainsPoint(CGRectInset(bounds, -CardFeedViewController.LineSpacing, -CardFeedViewController.LineSpacing), point)
    }
    var onTap: (() -> ())?
    func _tapped() {
        if let t = onTap { t() }
    }
}

class DescriptionCell: UICollectionViewCell {
    let label = UILabel()
    let bg = UIView()
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if label.superview == nil {
            contentView.addSubview(bg)
            bg.backgroundColor = UIColor(white: 0.95, alpha: 1)
            
            contentView.addSubview(label)
            label.textAlignment = NSTextAlignment.Left
            label.textColor = UIColor.blackColor()
            label.numberOfLines = 0
            
            let tapRec = UITapGestureRecognizer(target: self, action: #selector(TextCell._tapped))
            addGestureRecognizer(tapRec)
        }
    }
    static let VerticalPadding: CGFloat = 10
    static let HorizontalPadding: CGFloat = 10
    override func layoutSubviews() {
        super.layoutSubviews()
        let top: CGFloat = 100
        bg.frame = CGRectMake(0, -top, bounds.size.width, bounds.size.height + top)
        label.frame = CGRectMake(DescriptionCell.HorizontalPadding, 0, bounds.size.width - DescriptionCell.HorizontalPadding * 2, bounds.size.height - DescriptionCell.VerticalPadding)
    }
    var onTap: (() -> ())?
    func _tapped() {
        if let t = onTap { t() }
    }
}

class ButtonFeedCell: UICollectionViewCell {
    var value: (NSAttributedString, [(String, () -> ())])? {
        didSet {
            if label.superview == nil {
                // do setup:
                contentView.addSubview(label)
                label.textColor = UIColor.blackColor()
                label.textAlignment = .Left
                label.numberOfLines = 0
                label.alpha = 0.8
                label.userInteractionEnabled = true
                let tap = UITapGestureRecognizer(target: self, action: #selector(ButtonFeedCell.tappedText))
                label.addGestureRecognizer(tap)
            }
            if let (text, buttons) = value {
                label.attributedText = text
                self.buttons = buttons.map({
                    (title, _) -> UIButton in
                    let btn = UIButton()
                    btn.setTitle(title.uppercaseString, forState: .Normal)
                    btn.addTarget(self, action: #selector(ButtonFeedCell.clicked), forControlEvents: .TouchUpInside)
                    btn.setTitleColor(Appearance.tint, forState: .Normal)
                    btn.titleLabel!.font = NSAttributedString.defaultBoldFontAtSize(12)
                    return btn
                })
            }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        var x: CGFloat = bounds.size.width - CGFloat(buttons.count) * ButtonFeedCell.ButtonSize.width
        label.frame = CGRectMake(0, 0, x, bounds.size.height)
        if buttons.count > 0 {
            for btn in buttons {
                btn.frame = CGRectMake(x, 0, ButtonFeedCell.ButtonSize.width, bounds.size.height)
                x += ButtonFeedCell.ButtonSize.width
            }
        }
    }
    let label = UILabel()
    var buttons = [UIButton]() {
        didSet(oldVal) {
            for btn in oldVal {
                btn.removeFromSuperview()
            }
            for btn in buttons {
                addSubview(btn)
            }
        }
    }
    static let ButtonSize: CGSize = CGSizeMake(55, 40)
    func clicked(sender: UIButton) {
        if let idx = buttons.indexOf(sender), let (_, buttonList) = value {
            buttonList[idx].1()
        }
    }
    var tapAction: (() -> ())?
    func tappedText() {
        if let t = tapAction { t() }
    }
}
