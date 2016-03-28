//
//  HashtagViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class HashtagViewController: CardFeedViewController {
    var hashtag: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // start observing:
        let q = Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("cards").queryOrderedByChild("negativeDate")
        _fbHandle = q.observeEventType(FEventType.Value) { [weak self] (let snapshot: FDataSnapshot!) -> Void in
            self?.rows = snapshot.childDictionaries.map({ CardFeedViewController.RowModel.Card(id: $0["cardID"] as! String, hashtag: self!.hashtag) })
            if let rows = self?.rows {
                self?.nothingHere.hidden = rows.count > 0
            }
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
}
