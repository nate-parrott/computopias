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
    }
    var _fbHandle: UInt?
    deinit {
        if let h = _fbHandle {
            Data.firebase.removeObserverWithHandle(h)
        }
    }
    
    @IBOutlet var nothingHere: UIView!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    @IBAction func sendInitialMessage() {
        let editor = storyboard!.instantiateViewControllerWithIdentifier("Editor") as! CardEditor
        editor.hashtag = hashtag
        presentViewController(editor, animated: true, completion: nil)
    }
    
    @IBAction func sendAdditionalMessage() {
        
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
        cell.cardInfo = cards![indexPath.item]
        return cell
    }
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
                _fbHandle = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id).observeEventType(FEventType.Value, withBlock: { [weak self] (let snapshot) -> Void in
                    if let json = snapshot.value as? [String: AnyObject] {
                        self?.cardView.importJson(json)
                    }
                })
            }
        }
    }
    var _fbHandle: UInt?
}
