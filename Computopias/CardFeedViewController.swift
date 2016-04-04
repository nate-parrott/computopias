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
        
        collectionView.backgroundColor = UIColor.whiteColor()
        view.backgroundColor = UIColor.whiteColor()
        
        collectionView.registerClass(CardCell.self, forCellWithReuseIdentifier: "Card")
        collectionView.registerClass(TextCell.self, forCellWithReuseIdentifier: "Text")
        collectionView.registerClass(DescriptionCell.self, forCellWithReuseIdentifier: "Description")
        
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = UIEdgeInsetsMake(lineSpacing, 0, 0, 0)
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = lineSpacing
    }
    
    let lineSpacing: CGFloat = 10
    
    var rows = [RowModel]() {
        didSet(oldRows) {
            loadViewIfNeeded()
            
            var currentPosition: (RowModel, CGFloat)?
            if let i = indexOfCurrentlyViewedRow() {
                currentPosition = (_rows[i], collectionView.contentOffset.y - scrollOffsetForRowAtIndex(i, rows: _rows))
            }
            
            if isViewLoaded() {
                let changes = Diff.OrderActionsDeletionsFirst(Diff.Compute(rows, oldSeq: oldRows))
                if changes.count > 0 {
                    UIView.animateWithDuration(0.3, animations: {
                        
                        self.collectionView.performBatchUpdates({
                            self._rows = self.rows
                            for change in changes {
                                switch change {
                                case .Reload(let indices):
                                    self.collectionView.reloadItemsAtIndexPaths(indices.map({ NSIndexPath(forItem: $0, inSection: 0) }))
                                case .Insert(let indices):
                                    self.collectionView.insertItemsAtIndexPaths(indices.map({ NSIndexPath(forItem: $0, inSection: 0) }))
                                case .Delete(let indices):
                                    self.collectionView.deleteItemsAtIndexPaths(indices.map({ NSIndexPath(forItem: $0, inSection: 0) }))
                                }
                            }
                            if let (row, offset) = currentPosition {
                                if let index = self.rows.indexOf({ $0 == row }) {
                                    self.collectionView.contentOffset = CGPointMake(0, self.scrollOffsetForRowAtIndex(index, rows: self.rows) + offset)
                                }
                            }
                            }, completion: { (_) in
                        })
                        
                        }, completion: { (_) in
                            
                    })
                }
            } else {
                _rows = rows
            }
        }
    }
    var _rows = [RowModel]()
    
    enum RowModel: Equatable {
        case Card(id: String, hashtag: String?)
        case Caption(text: NSAttributedString, action: (() -> ())?)
        case Description(text: NSAttributedString, action: (() -> ())?)
        
        func sizeForWidth(width: CGFloat) -> CGSize {
            switch self {
            case .Card(id: _, hashtag: _):
                return CardView.CardSize
            case .Caption(text: let text, action: _):
                let height = text.boundingRectWithSize(CGSizeMake(CardView.CardSize.width, 500), options: [.UsesLineFragmentOrigin], context: nil).size.height
                return CGSizeMake(CardView.CardSize.width, height)
            case .Description(text: let text, _):
                let height = text.boundingRectWithSize(CGSizeMake(width, 500), options: [.UsesLineFragmentOrigin], context: nil).size.height
                return CGSizeMake(width, height + DescriptionCell.VerticalPadding)
            }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    func scrollOffsetForRowAtIndex(i: Int, rows: [RowModel]) -> CGFloat {
        var y = lineSpacing
        var j = 0
        for row in rows {
            if j == i {
                return y
            } else {
                y += row.sizeForWidth(collectionView.bounds.size.width).height + lineSpacing
                j += 1
            }
        }
        return 0
    }
    
    func indexOfCurrentlyViewedRow() -> Int? {
        let pt = collectionView.frame.center
        var closestCell: UICollectionViewCell?
        for cell in collectionView.visibleCells() {
            let cellDist = (view.convertRect(cell.bounds, fromView: cell).center - pt).magnitude
            if closestCell == nil || cellDist < (view.convertRect(closestCell!.bounds, fromView: closestCell!).center - pt).magnitude {
                closestCell = cell
            }
        }
        if let cell = closestCell {
            return collectionView.indexPathForCell(cell)?.item
        } else {
            return nil
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _rows.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = collectionView.bounds.size.width
        return _rows[indexPath.item].sizeForWidth(width)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        switch _rows[indexPath.item] {
        case .Card(id: let id, hashtag: let hashtag):
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Card", forIndexPath: indexPath) as! CardCell
            cell.card = (id: id, hashtag: hashtag)
            return cell
        case .Caption(text: let text, action: _):
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Text", forIndexPath: indexPath) as! TextCell
            cell.label.attributedText = text
            return cell
        case .Description(text: let text, action: _):
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Description", forIndexPath: indexPath) as! DescriptionCell
            cell.label.attributedText = text
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        switch _rows[indexPath.item] {
        case .Caption(text: _, action: let actionOpt):
            if let a = actionOpt {
                a()
            }
        case .Description(text: _, action: let actionOpt):
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
                let text = NSAttributedString.smallBoldText(posterName) + NSAttributedString.smallText(" on " + dateString)
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
