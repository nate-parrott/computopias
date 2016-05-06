//
//  CardEditor.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardEditor: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var hashtag: String!
    var template: [String: AnyObject]?
    
    var existingID: String?
    var existingContent: [String: AnyObject]?
    
    @IBOutlet var cardViewContainer: UIView!
    var cardView: CardView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var promptLabel: UILabel!
    
    var onPost: ((CardID: String) -> ())?
    var onPrePost: (() -> ())?
    
    @IBOutlet var itemInserterCollectionViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardView = CardView()
        cardViewContainer.addSubnode(cardView)
        cardViewContainer.backgroundColor = nil
        view.tintColor = UIColor.whiteColor()
        collectionView.hidden = true
        var prompt = ""
        if let t = template {
            prompt = "New Post"
            // we already have a template, so don't allow editing it:
            cardView.importJson(t, callback: {
                for item in self.cardView.items {
                    item.detachFromTemplate()
                    item.prepareToEditWithExistingTemplate()
                }
            })
        } else if let existing = existingContent {
            prompt = "Edit Card"
            cardView.importJson(existing, callback: {
                let allowTemplateEditing = self.hashtag == "profiles"
                for item in self.cardView.items {
                    item.prepareToEditInPlace(allowTemplateEditing)
                }
                self.collectionView.hidden = !allowTemplateEditing
            })
        } else {
            // we're building a new template; add initial content:
            // addItemView(ProfileCardItemView())
            prompt = "First post in #\(hashtag)"
            collectionView.hidden = false
        }
        promptLabel.text = prompt
        
        if UIScreen.mainScreen().bounds.size.height < 500 {
            itemInserterCollectionViewHeight.constant = 80
        }
    }
    
    struct Item {
        var title: String
        var image: UIImage?
        var callback: () -> CardItemView!
    }
    
    let items: [Item] = [
        Item(title: "Label", image: UIImage(named: "EdLabel"), callback: { () -> CardItemView! in
            let l = TextCardItemView()
            l.staticLabel = false
            return l
        }),
        Item(title: "Caption", image: UIImage(named: "EdCaption"), callback: { () -> CardItemView! in
            let l = TextCardItemView()
            l.staticLabel = false
            l.backgrounded = true
            return l
        }),
        Item(title: "Image", image: UIImage(named: "EdPhoto"), callback: { () -> CardItemView! in
            let m = ImageCardItemView()
            return m
        }),
        Item(title: "Scribble", image: UIImage(named: "EdScribble"), callback: { () -> CardItemView! in
            return DrawingCardItemView()
        }),
        /*Item(title: "Profile", image: UIImage(named: "profile"), callback: { () -> CardItemView! in
            return ProfileCardItemView()
        }),*/
        Item(title: "Comments", image: UIImage(named: "EdComments"), callback: { () -> CardItemView! in
            return CommentsCardItemView()
        }),
        Item(title: "Likes", image: UIImage(named: "EdLike"), callback: { () -> CardItemView! in
            return LikeCounterCardItemView()
        }),
        Item(title: "Counter", image: UIImage(named: "EdCounter"), callback: { () -> CardItemView! in
            return CounterCardItemView()
        }),
        Item(title: "Recording", image: UIImage(named: "EdSound"), callback: { () -> CardItemView! in
            return SoundCardItemView()
        }),
        Item(title: "Button", image: UIImage(named: "EdLink"), callback: { () -> CardItemView! in
            return ButtonCardItemView()
        }),
        Item(title: "Location", image: UIImage(named: "EdLocation"), callback: { () -> CardItemView! in
            return MapCardItemView()
        }),
        /*Item(title: "MessageMe", image: UIImage(named: "sms"), callback: { () -> CardItemView! in
            return MessageMeCardItemView()
        }),*/
        Item(title: "Random", image: UIImage(named: "EdRandom"), callback: { () -> CardItemView! in
            return RandomContentCardItemView()
        }),
        Item(title: "Rating", image: UIImage(named: "EdRating"), callback: { () -> CardItemView! in
            return StarRatingCardItemView()
        }),
        Item(title: "Title", image: UIImage(named: "EdTitle"), callback: { () -> CardItemView! in
            /*let l = TextCardItemView()
            l.staticLabel = false
            l.size = 2
            return l*/
            return LargeTextCardItemView()
        })
        /*Item(title: "Timer", image: UIImage(named: "timer"), callback: { () -> CardItemView! in
            return nil
        }),*/
        /*Item(title: "Destruct", image: UIImage(named: "destruct"), callback: { () -> CardItemView! in
            return CountdownCardItemView()
        })*/
    ]
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CardEditorItemCell
        cell.imageView.image = items[indexPath.item].image
        cell.label.text = items[indexPath.item].title
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let itemView = items[indexPath.item].callback() {
            itemView.prepareToEditTemplate()
            addItemView(itemView)
        }
    }
    
    func addItemView(itemView: CardItemView) {
        var size = CGSizeMake(itemView.defaultSize.width * cardView.gridCellSize.width, itemView.defaultSize.height * cardView.gridCellSize.height)
        if size.width < 0 { size.width = cardView.bounds.size.width }
        if size.height < 0 { size.height = cardView.bounds.size.height }
        itemView.frame = findFrameForItemWithSize(size)
            
        cardView.itemsNode.addSubnode(itemView)
        
        delay(0, closure: { () -> () in
            itemView.onInsert()
        })
    }
    
    func findFrameForItemWithSize(size: CGSize) -> CGRect {
        let itemFrames = cardView.items.map({ $0.frame })
        let frameIsOccupied = {
            (frame: CGRect) -> Bool in
            for f in itemFrames {
                if CGRectIntersectsRect(f, frame) {
                    return true
                }
            }
            return false
        }
        
        var y: CGFloat = 0
        while y + size.height <= CardView.CardSize.height {
            var x: CGFloat = 0
            while x + size.width <= CardView.CardSize.width {
                let frame = CGRectMake(x, y, size.width, size.height)
                if !frameIsOccupied(frame) {
                    return frame
                }
                x += cardView.gridCellSize.width
            }
            y += cardView.gridCellSize.height
        }
        return CGRectMake(0, 0, size.width, size.height)
    }
    
    @IBAction func send() {
        if let p = onPrePost {
            p()
        }
        
        var cardJson = cardView.toJson()
        cardJson["hashtag"] = hashtag
        cardJson["poster"] = Data.profileJson()
        cardJson["date"] = NSDate().timeIntervalSince1970
        let card = existingID != nil ? Data.firebase.childByAppendingPath("cards").childByAppendingPath(existingID!) : Data.firebase.childByAppendingPath("cards").childByAutoId()
        card.setValue(cardJson)
        
        Data.createOrUpdateHashtag(hashtag, cardID: card.key)
        
        Data.broadcastCardUpdate(card.key, hashtag: hashtag)
    
        if template == nil {
            // save this as a template:
            Data.firebase.childByAppendingPath("templates").childByAppendingPath(hashtag).setValue(cardJson)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
        
        if let p = onPost {
            p(CardID: card.key!)
        }
        
        Data.setFollowing(hashtag, following: true, type: .Hashtag)
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let padding = (collectionView.bounds.size.height - flowLayout.itemSize.height) / 2
        flowLayout.minimumLineSpacing = padding
        flowLayout.minimumInteritemSpacing = padding
        
        /*let nCols = Int(ceil(Float(items.count) / 2.0))
        let contentWidth = CGFloat(nCols + 1) * padding + CGFloat(nCols) * flowLayout.itemSize.width
        let leftPadding = padding + max(0, (collectionView.bounds.size.width - contentWidth)/2)*/
        
        collectionView.contentInset = UIEdgeInsetsMake(padding, padding, padding, padding)
        
        cardView.frame = cardViewContainer.bounds
    }
    
}

class CardEditorItemCell: UICollectionViewCell {
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
}

