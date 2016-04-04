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
    
    @IBOutlet var cardView: CardView!
    @IBOutlet var collectionView: UICollectionView!
    
    var onPost: ((CardID: String) -> ())?
    var onPrePost: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardView.backgroundImageView.image = Appearance.gradientForHashtag(hashtag, cardID: nil)
        view.tintColor = cardView.backgroundColor
        collectionView.hidden = true
        if let t = template {
            // we already have a template, so don't allow editing it:
            cardView.importJson(t)
            for item in cardView.items {
                item.detachFromTemplate()
                item.prepareToEditWithExistingTemplate()
            }
        } else if let existing = existingContent {
            cardView.importJson(existing)
            let allowTemplateEditing = hashtag == "profiles"
            for item in cardView.items {
                item.prepareToEditInPlace(allowTemplateEditing)
            }
            collectionView.hidden = !allowTemplateEditing
        } else {
            // we're building a new template; add initial content:
            // addItemView(ProfileCardItemView())
            collectionView.hidden = false
        }
    }
    
    struct Item {
        var title: String
        var image: UIImage?
        var callback: () -> CardItemView!
    }
    
    let items: [Item] = [
        Item(title: "Label", image: UIImage(named: "label"), callback: { () -> CardItemView! in
            let l = TextCardItemView()
            l.staticLabel = true
            return l
        }),
        Item(title: "Text", image: UIImage(named: "editable_text"), callback: { () -> CardItemView! in
            let l = TextCardItemView()
            l.staticLabel = false
            return l
        }),
        Item(title: "Image", image: UIImage(named: "image"), callback: { () -> CardItemView! in
            let m = ImageCardItemView()
            return m
        }),
        /*Item(title: "Profile", image: UIImage(named: "profile"), callback: { () -> CardItemView! in
            return ProfileCardItemView()
        }),*/
        Item(title: "Button", image: UIImage(named: "link"), callback: { () -> CardItemView! in
            return ButtonCardItemView()
        }),
        Item(title: "Counter", image: UIImage(named: "vote"), callback: { () -> CardItemView! in
            return CounterCardItemView()
        }),
        Item(title: "Likes", image: UIImage(named: "like"), callback: { () -> CardItemView! in
            return LikeCounterCardItemView()
        }),
        Item(title: "Sound", image: UIImage(named: "audio"), callback: { () -> CardItemView! in
            return SoundCardItemView()
        }),
        Item(title: "Location", image: UIImage(named: "location"), callback: { () -> CardItemView! in
            return MapCardItemView()
        }),
        Item(title: "Comment", image: UIImage(named: "comment"), callback: { () -> CardItemView! in
            return CommentsCardItemView()
        }),
        Item(title: "MessageMe", image: UIImage(named: "sms"), callback: { () -> CardItemView! in
            return MessageMeCardItemView()
        }),
        Item(title: "Drawing", image: UIImage(named: "drawing"), callback: { () -> CardItemView! in
            return DrawingCardItemView()
        }),
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
        if let image = items[indexPath.item].image {
            cell.label.text = ""
            cell.imageView.image = image.imageWithRenderingMode(.AlwaysTemplate)
        } else {
            cell.imageView.image = nil
            cell.label.text = items[indexPath.item].title
        }
        cell.label.backgroundColor = Appearance.colors[indexPath.item % Appearance.colors.count]
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
            
        cardView.addSubview(itemView)
        
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
        let padding = (collectionView.bounds.size.height - flowLayout.itemSize.height * 2) / 3
        flowLayout.minimumLineSpacing = padding
        flowLayout.minimumInteritemSpacing = padding
        
        let nCols = Int(ceil(Float(items.count) / 2.0))
        let contentWidth = CGFloat(nCols + 1) * padding + CGFloat(nCols) * flowLayout.itemSize.width
        let leftPadding = padding + max(0, (collectionView.bounds.size.width - contentWidth)/2)
        
        collectionView.contentInset = UIEdgeInsetsMake(padding, leftPadding, padding, padding)
    }
}

class CardEditorItemCell: UICollectionViewCell {
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.layer.cornerRadius = label.bounds.size.height/2
        label.clipsToBounds = true
    }
}

