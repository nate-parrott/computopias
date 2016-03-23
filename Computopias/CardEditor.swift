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
        var callback: () -> CardItemView!
    }
    
    let items: [Item] = [
        Item(title: "Label", callback: { () -> CardItemView! in
            let l = TextCardItemView()
            l.staticLabel = true
            return l
        }),
        Item(title: "Text", callback: { () -> CardItemView! in
            let l = TextCardItemView()
            l.staticLabel = false
            return l
        }),
        Item(title: "Long text", callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Image", callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Button", callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Upvote", callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Sound", callback: { () -> CardItemView! in
            return nil
        }),
        Item(title: "Counter", callback: { () -> CardItemView! in
            return nil
        })
    ]
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CardEditorItemCell
        cell.label.text = items[indexPath.item].title
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
}

