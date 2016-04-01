//
//  CardFeed.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class CardFeedViewController: NavigableViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = UIColor.blackColor()
        view.backgroundColor = UIColor.blackColor()
        
        collectionView.registerClass(CardCell.self, forCellWithReuseIdentifier: "Card")
        collectionView.registerClass(TextCell.self, forCellWithReuseIdentifier: "Text")
        
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = UIEdgeInsetsMake(10, 0, 0, 0)
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 10
    }
    
    var rows = [RowModel]() {
        didSet(oldRows) {
            loadViewIfNeeded()
            let changes = Diff.Compute(rows, oldSeq: oldRows)
            if changes.count > 0 {
                collectionView.performBatchUpdates({
                    for change in changes.reverse() {
                        switch change {
                        case .Reload(let indices):
                            self.collectionView.reloadItemsAtIndexPaths(indices.map({ NSIndexPath(forItem: $0, inSection: 0) }))
                        case .Insert(let indices):
                            self.collectionView.insertItemsAtIndexPaths(indices.map({ NSIndexPath(forItem: $0, inSection: 0) }))
                        case .Delete(let indices):
                            self.collectionView.deleteItemsAtIndexPaths(indices.map({ NSIndexPath(forItem: $0, inSection: 0) }))
                        }
                    }
                }, completion: nil)
            }
        }
    }
    
    enum RowModel: Equatable {
        case Card(id: String, hashtag: String?)
        case Caption(text: NSAttributedString, action: (() -> ())?)
        
        func sizeForWidth(width: CGFloat) -> CGSize {
            switch self {
            case .Card(id: _, hashtag: _):
                return CardView.CardSize
            case .Caption(text: let text, action: _):
                return text.boundingRectWithSize(CGSizeMake(CardView.CardSize.width, 400), options: [.UsesLineFragmentOrigin], context: nil).size
            }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = collectionView.bounds.size.width
        return rows[indexPath.item].sizeForWidth(width)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        switch rows[indexPath.item] {
        case .Card(id: let id, hashtag: let hashtag):
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Card", forIndexPath: indexPath) as! CardCell
            cell.card = (id: id, hashtag: hashtag)
            return cell
        case .Caption(text: let text, action: _):
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Text", forIndexPath: indexPath) as! TextCell
            cell.label.attributedText = text
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        switch rows[indexPath.item] {
        case .Caption(text: _, action: let actionOpt):
            if let a = actionOpt {
                a()
            }
        default: ()
        }
    }
    // MARK: Convenience
    func cellForCardWithID(id: String) -> CardCell? {
        for cell in collectionView.visibleCells() {
            if let cardID = (cell as? CardCell)?.card?.id where cardID == id {
                return (cell as! CardCell)
            }
        }
        return nil
    }
    // MARK: Row creation
    func createRowsForCardDicts(cardDicts: [[String: AnyObject]]) -> [RowModel] {
        var rows = [RowModel]()
        for dict in cardDicts {
            if let cardID = dict["cardID"] as? String,
                let poster = dict["poster"] as? [String: AnyObject],
                let posterName = poster["name"] as? String,
                let posterId = poster["uid"] as? String,
                let hashtag = dict["hashtag"] as? String,
                let date = dict["date"] as? Double {
                
                let dateString = NSDateFormatter.localizedStringFromDate(NSDate(timeIntervalSince1970: date), dateStyle: .ShortStyle, timeStyle: .ShortStyle)
                let text = NSAttributedString.defaultUnderlinedText(posterName) + NSAttributedString.defaultText(" on " + dateString)
                let caption = RowModel.Caption(text: text, action: { 
                    [weak self] in
                    self?.navigate(Route.forProfile(posterId))
                })
                let card = RowModel.Card(id: cardID, hashtag: hashtag)
                rows += [caption, card]
            }
        }
        return rows
    }
}

class CardCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(cardView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let cardView = CardView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.bounds = CGRectMake(0, 0, CardView.CardSize.width, CardView.CardSize.height)
        cardView.center = bounds.center
    }
    
    var card: (id: String, hashtag: String?)? {
        didSet {
            if let h = _fbHandle {
                Data.firebase.removeObserverWithHandle(h)
            }
            _fbHandle = nil
            
            if let (id, hashtag) = card {
                let cardFirebase = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id)
                cardView.cardFirebase = cardFirebase
                cardView.hashtag = hashtag
                cardView.backgroundImageView.image = Appearance.gradientForHashtag(hashtag ?? "")
                _fbHandle = cardFirebase.observeEventType(FEventType.Value, withBlock: { [weak self] (let snapshot) -> Void in
                    if let json = snapshot.value as? [String: AnyObject] {
                        self?.cardView.importJson(json)
                        for item in self?.cardView.items ?? [] {
                            item.prepareToPresent()
                        }
                    }
                    })
            }
        }
    }
    var _fbHandle: UInt?
}

class TextCell: UICollectionViewCell {
    let label = UILabel()
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if label.superview == nil {
            contentView.addSubview(label)
            label.textAlignment = NSTextAlignment.Center
            label.textColor = UIColor.whiteColor()
            label.alpha = 0.8
            label.numberOfLines = 0
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRectMake((bounds.size.width - CardView.CardSize.width)/2, 0, CardView.CardSize.width, bounds.size.height)
    }
    enum TextFormats {
        case Normal(text: String)
        case Highlighted(text: String)
    }
}

func ==(m1: CardFeedViewController.RowModel, m2: CardFeedViewController.RowModel) -> Bool {
    switch (m1, m2) {
    case (.Card(id: let id1, hashtag: let tag1), .Card(id: let id2, hashtag: let tag2)):
        return id1 == id2 && tag1 == tag2
    case (.Caption(text: let text1, action: _), .Caption(text: let text2, action: _)):
        return text1 == text2
    default:
        return false
    }
}
