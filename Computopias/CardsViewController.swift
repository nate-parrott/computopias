//
//  CardsViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/20/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardsViewController: NavigableViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(CardCell.self, forCellWithReuseIdentifier: "CardItem")
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        view.addSubview(collectionView)
        collectionView.backgroundColor = UIColor.whiteColor()
    }
    
    // MARK: CollectionView
    var collectionView: UICollectionView!
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return modelItems.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = modelItems[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(item.cellIdentifier, forIndexPath: indexPath)
        item.populateCell(cell)
        return cell
    }
    
    // MARK: Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = .Horizontal
        layout.itemSize = CardCell.Size
        layout.minimumLineSpacing = 15
        let xInset = (view.bounds.size.width - layout.itemSize.width)/2
        let yInset = (view.bounds.size.height - layout.itemSize.height)/2
        collectionView.contentInset = UIEdgeInsetsMake(yInset, xInset, yInset, xInset)
        
        // layout buttons:
        let buttonFrame = CGRectMake(0, view.bounds.size.height - yInset, view.bounds.size.width, yInset)
        let paddedButtons = buttons.map({ EVInset($0, UIEdgeInsetsMake(4, 4, 4, 4)) })
        EVComplexLayout(false, buttonFrame, [EVVertical(), EVLayoutAlignCenter(), [EVHorizontal(), EVLayoutAlignCenter()] + paddedButtons])
    }
    
    // MARK: Models
    class Item {
        var cellIdentifier: String! { get { return nil } }
        func populateCell(cell: UICollectionViewCell) {}
    }
    class CardItem: Item {
        init?(dict: [String: AnyObject], vc: NavigableViewController) {
            if let cardID = dict["cardID"] as? String,
                let poster = dict["poster"] as? [String: AnyObject],
                let posterName = poster["name"] as? String,
                let posterId = poster["uid"] as? String,
                let hashtag = dict["hashtag"] as? String,
                let date = dict["date"] as? Double {
                if Data.userIsBlocked(posterId) { return nil }
                
                let dateString = NSDateFormatter.localizedStringFromDate(NSDate(timeIntervalSince1970: date), dateStyle: .ShortStyle, timeStyle: .ShortStyle)
                caption = NSAttributedString.smallBoldText(posterName + " ›") + NSAttributedString.smallText(" on " + dateString)
                captionAction = {
                    [weak vc] in
                    vc?.navigate(Route.forProfile(posterId))
                }
                self.cardID = cardID
                self.hashtag = hashtag
            } else {
                return nil
            }
        }
        override var cellIdentifier: String {
            get {
                return "CardItem"
            }
        }
        override func populateCell(cell: UICollectionViewCell) {
            super.populateCell(cell)
            let c = cell as! CardCell
            c.card = (cardID, hashtag)
            c.label.attributedText = caption
            c.captionTapAction = captionAction
        }
        var cardID: String!
        var hashtag: String?
        var caption: NSAttributedString?
        var captionAction: (() -> ())?
    }
    
    var modelItems = [Item]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // MARK: Buttons
    var buttons = [UIButton]() {
        didSet {
            for b in oldValue {
                b.removeFromSuperview()
            }
            for b in buttons {
                view.addSubview(b)
            }
        }
    }
}
