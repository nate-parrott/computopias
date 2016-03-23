//
//  CardFeed.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class CardFeedViewController: UIViewController, UICollectionViewDataSource {
    var hashtag: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cards = nil
        // start observing:
        let q = Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("cards").queryOrderedByChild("negativeDate")
        _fbHandle = q.observeEventType(FEventType.Value) { [weak self] (let snapshot: FDataSnapshot!) -> Void in
            self?.cards = snapshot.childDictionaries
        }
        navBackdropView.backgroundColor = Appearance.colorForHashtag(hashtag)
        view.tintColor = navBackdropView.backgroundColor
    }
    var _fbHandle: UInt?
    deinit {
        if let h = _fbHandle {
            Data.firebase.removeObserverWithHandle(h)
        }
    }
    
    @IBOutlet var nothingHere: UIView!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    @IBAction func addPost() {
        // get the template:
        Data.firebase.childByAppendingPath("templates").childByAppendingPath(hashtag).observeSingleEventOfType(FEventType.Value) { (let snapshot: FDataSnapshot!) -> Void in
            let editor = self.storyboard!.instantiateViewControllerWithIdentifier("Editor") as! CardEditor
            editor.hashtag = self.hashtag
            if let template = snapshot.value as? [String: AnyObject] {
                editor.template = template
            }
            self.presentViewController(editor, animated: true, completion: nil)
        }
    }
    
    // /hashtags/<hashtag>/cards; each contains {id: id, date: date}
    var cards: [[String: AnyObject]]? {
        didSet {
            nothingHere.hidden = cards == nil || cards!.count > 0
            loader.hidden = cards != nil
            collectionView.reloadData()
            collectionView.hidden = cards == nil || cards!.count == 0
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards?.count ?? 0
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CardCell
        var cardInfo = cards![indexPath.item]
        cardInfo["hashtag"] = hashtag
        cell.cardInfo = cardInfo
        cell.cardView.backgroundColor = Appearance.colorForHashtag(hashtag)
        return cell
    }
    
    // MARK: Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let padding = (collectionView.bounds.size.width - CardView.CardSize.width) / 2
        collectionView.contentInset = UIEdgeInsetsMake(padding, padding, padding, padding)
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = padding
    }
    
    @IBOutlet var navBackdropView: UIView!
}

class CardCell: UICollectionViewCell {
    @IBOutlet var cardView: CardView!
    var cardInfo: [String: AnyObject]? {
        didSet {
            if let h = _fbHandle {
                Data.firebase.removeObserverWithHandle(h)
            }
            _fbHandle = nil
            
            if let id = cardInfo?["cardID"] as? String {
                let cardFirebase = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id)
                cardView.cardFirebase = cardFirebase
                cardView.hashtag = cardInfo?["hashtag"] as? String
                _fbHandle = cardFirebase.observeEventType(FEventType.Value, withBlock: { [weak self] (let snapshot) -> Void in
                    if let json = snapshot.value as? [String: AnyObject] {
                        self?.cardView.importJson(json)
                        for item in self?.cardView.items ?? [] {
                            item.editMode = false
                            item.templateEditMode = false
                            item.onPresent()
                        }
                    }
                })
            }
        }
    }
    var _fbHandle: UInt?
}
