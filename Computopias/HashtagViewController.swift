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
        createToolbar()
        // start observing:
        nothingHere.hidden = true
        let q = Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("cards").queryOrderedByChild("negativeDate")
        _fbHandle = q.observeEventType(FEventType.Value) { [weak self] (let snapshot: FDataSnapshot!) -> Void in
            if let s = self {
                s.rows = s.createRowsForCardDicts(snapshot.childDictionaries)
                s.nothingHere.hidden = (s.rows.count > 0)
            }
        }
        _followingSub = Data.isFollowingItem(hashtag).subscribe({ [weak self] (let following) in
            self?.following = following
        })
    }
    var _fbHandle: UInt?
    deinit {
        if let h = _fbHandle {
            Data.firebase.removeObserverWithHandle(h)
        }
    }
    
    @IBOutlet var nothingHere: UIView!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    func createToolbar() {
        let addPost = UIBarButtonItem(title: "Add Post", style: .Plain, target: self, action: #selector(HashtagViewController.addPost))
        followButton = UIBarButtonItem(title: "Follow", style: .Plain, target: self, action: #selector(HashtagViewController.toggleFollowing))
        toolbarItems = [addPost, followButton]
    }
    
    // MARK: Following
    var following: Bool? {
        didSet {
            followButton.title = following ?? false ? "Following" : "Follow"
        }
    }
    var _followingSub: Subscription?
    var followButton: UIBarButtonItem!
    
    func toggleFollowing() {
        Data.setFollowing(hashtag, following: !(following ?? false), isUser: false)
    }
    
    // MARK: Posting
    
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
}
