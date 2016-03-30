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
        collectionView.registerClass(CardCell.self, forCellWithReuseIdentifier: "Card")
    }
    
    var rows = [RowModel]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    enum RowModel {
        case Card(id: String, hashtag: String?)
        
        func sizeForWidth(width: CGFloat) -> CGSize {
            switch self {
            case .Card(id: _, hashtag: _):
                return CardView.CardSize
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
        }
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
                cardView.backgroundColor = Appearance.colorForHashtag(hashtag ?? "")
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
