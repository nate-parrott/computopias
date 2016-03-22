//
//  CardFeed.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class CardFeedViewController: UIViewController {
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
            // TODO: reload collection
        }
    }
}
