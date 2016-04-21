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
        
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = UIEdgeInsetsMake(lineSpacing, 0, 0, 0)
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = lineSpacing
    }
    
    static let LineSpacing: CGFloat = 10
    let lineSpacing: CGFloat = CardFeedViewController.LineSpacing
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // _timeViewAppeared = CFAbsoluteTimeGetCurrent()
    }
    
    var rows = [RowModel]() {
        didSet(oldRows) {
            loadViewIfNeeded()
            
            var currentPosition: (RowModel, CGFloat)?
            if let i = indexOfCurrentlyViewedRow() {
                currentPosition = (_rows[i], collectionView.contentOffset.y - scrollOffsetForRowAtIndex(i, rows: _rows))
            }
            
            let changes = Diff.OrderActionsDeletionsFirst(Diff.Compute(rows, oldSeq: oldRows))
            if changes.count > 0 {
                let performUpdates: (() -> ()) = {
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
                        if let (row, offset) = currentPosition where !self.collectionView.isAtTop {
                            if let index = self.rows.indexOf({ $0 == row }) {
                                self.collectionView.contentOffset = CGPointMake(0, self.scrollOffsetForRowAtIndex(index, rows: self.rows) + offset)
                            }
                        }
                        }, completion: { (_) in
                    })
                }
                
                let animate = false
                
                if animate {
                    UIView.animateWithDuration(0.3, animations: {
                        performUpdates()
                        }, completion: { (_) in
                    })
                } else {
                    UIView.performWithoutAnimation({ 
                        performUpdates()
                    })
                }
            }
        }
    }
    var _rows = [RowModel]()
    
    enum RowModel: Equatable {
        case Card(id: String, hashtag: String?)
        case Caption(text: NSAttributedString, action: (() -> ())?)
        case ButtonCell(text: NSAttributedString, action: (() -> ())?, buttons: [(String, () -> ())])
        case Description(text: NSAttributedString, action: (() -> ())?)
        case CaptionedCard(id: String, hashtag: String?, caption: NSAttributedString, captionAction: (() -> ())?)
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    func scrollOffsetForRowAtIndex(i: Int, rows: [RowModel]) -> CGFloat {
        // TODO
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
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        switch _rows[indexPath.item] {
        case .CaptionedCard(id: let id, hashtag: let hashtag, caption: let caption, captionAction: let captionAction):
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Card", forIndexPath: indexPath) as! CardCell
            cell.card = (id: id, hashtag: hashtag)
            cell.label.attributedText = caption
            cell.captionTapAction = captionAction
            return cell
        default: fatalError()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
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
                if Data.userIsBlocked(posterId) { continue }
                
                let dateString = NSDateFormatter.localizedStringFromDate(NSDate(timeIntervalSince1970: date), dateStyle: .ShortStyle, timeStyle: .ShortStyle)
                let text = NSAttributedString.smallBoldText(posterName + " ›") + NSAttributedString.smallText(" on " + dateString)
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
    case (.Description(let text1, action: _), .Description(let text2, action: _)):
        return text1 == text2
    case (.ButtonCell(let title1, _, let buttons1), .ButtonCell(let title2, _, let buttons2)):
        if title1 != title2 { return false }
        if buttons1.count != buttons2.count { return false }
        for ((b1, _), (b2, _)) in zip(buttons1, buttons2) {
            if b1 == b2 { return false }
        }
        return true
    default:
        return false
    }
}
