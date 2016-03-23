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
    
    @IBOutlet var cardView: CardView!
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardView.backgroundColor = Appearance.colorForHashtag(hashtag)
        if let t = template {
            // we already have a template, so don't allow editing it:
            collectionView.hidden = true
            cardView.importJson(t)
            for item in cardView.items {
                item.templateEditMode = false
            }
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
        Item(title: "Long text", image: nil, callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Image", image: UIImage(named: "image"), callback: { () -> CardItemView! in
            let m = ImageCardItemView()
            delay(0, closure: { () -> () in
                m.insertMedia()
            })
            return m
        }),
        Item(title: "Button", image: UIImage(named: "link"), callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Upvote", image: nil, callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Sound", image: UIImage(named: "audio"), callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Counter", image: nil, callback: { () -> CardItemView! in
            return nil
        })
    ]
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CardEditorItemCell
        if let image = items[indexPath.item].image {
            cell.label.text = ""
            cell.imageView.image = image
        } else {
            cell.imageView.image = nil
            cell.label.text = items[indexPath.item].title
        }
        cell.label.backgroundColor = Appearance.colors[indexPath.item % Appearance.colors.count]
        return cell
    }
    
    var gridCellSize: CGSize {
        get {
            return CGSizeMake(44, 44)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let itemView = items[indexPath.item].callback() {
            cardView.addSubview(itemView)
            var frame = CGRectMake(0, 0, itemView.defaultSize.width * gridCellSize.width, itemView.defaultSize.height * gridCellSize.height)
            if frame.size.width < 0 { frame.size.width = cardView.bounds.size.width }
            if frame.size.height < 0 { frame.size.height = cardView.bounds.size.height }
            itemView.frame = frame
        }
    }
    
    @IBAction func send() {
        let cardJson = cardView.toJson()
        let card = Data.firebase.childByAppendingPath("cards").childByAutoId()
        card.setValue(cardJson)
        
        let cardInfo: [String: AnyObject] = ["date": NSDate().timeIntervalSince1970, "negativeDate": -NSDate().timeIntervalSince1970, "cardID": card.key]
        Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("cards").childByAutoId().setValue(cardInfo)
        
        Data.firebase.childByAppendingPath("all_hashtags").childByAppendingPath(hashtag).childByAppendingPath("hashtag").setValue(hashtag)
        Data.firebase.childByAppendingPath("all_hashtags").childByAppendingPath(hashtag).childByAppendingPath("negativeDate").setValue(-NSDate().timeIntervalSince1970)
        
        if template == nil {
            // save this as a template:
            Data.firebase.childByAppendingPath("templates").childByAppendingPath(hashtag).setValue(cardJson)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

class CardEditorItemCell: UICollectionViewCell {
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.layer.cornerRadius = label.bounds.size.height/2
    }
}

