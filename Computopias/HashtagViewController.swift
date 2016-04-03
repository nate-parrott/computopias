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
    }
    
    override func startUpdating() {
        super.startUpdating()
        
        nothingHere.hidden = true
        
        let hashtagFB = Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag)
        
        let q = hashtagFB.childByAppendingPath("cards").queryOrderedByChild("negativeDate").queryLimitedToFirst(50)
        _cardsSub = q.snapshotPusher.subscribe({ [weak self] (let snapshotOpt) in
            if let s = self, let snapshot = snapshotOpt {
                s._cardRows = s.createRowsForCardDicts(snapshot.childDictionaries)
                s.nothingHere.hidden = (s.rows.count > 0)
            }
        })
        _followingSub = Data.isFollowingItem(hashtag).subscribe({ [weak self] (let following) in
            self?.following = following
        })
        _infoSub = hashtagFB.childByAppendingPath("info").pusher.subscribe({ [weak self] (let info) in
            if let infoDict = info as? [String: AnyObject], let desc = infoDict["description"] as? String {
                self?.hashtagDescription = desc
            } else {
                self?.hashtagDescription = nil
            }
            self?._updateGroupInfo()
        })
        _ownersSub = hashtagFB.childByAppendingPath("owners").pusher.subscribe({ [weak self] (let owners) in
            self?.ownerIsSelf = false
            self?.ownerName = nil
            if let ownersDict = owners as? [String: AnyObject] {
                if ownersDict[Data.getUID()!] != nil {
                    self?.ownerIsSelf = true
                    self?.ownerName = Data.getName()
                } else if let firstOwnerID = ownersDict.keys.first, let firstOwnerDict = ownersDict[firstOwnerID] as? [String: AnyObject], let firstOwnerName = firstOwnerDict["name"] as? String {
                    self?.ownerName = firstOwnerName
                }
            }
            self?._updateGroupInfo()
        })
    }
    
    override func stopUpdating() {
        super.stopUpdating()
        _cardsSub = nil
        _followingSub = nil
        _infoSub = nil
        _ownersSub = nil
    }
    
    // MARK: Rows
    
    var _cardRows = [RowModel]() {
        didSet {
            _updateRows()
        }
    }
    func _updateRows() {
        var r = [RowModel]()
        if let g = groupInfoRow {
            r.append(g)
        }
        r += _cardRows
        self.rows = r
    }
    
    var _cardsSub: Subscription?
    
    @IBOutlet var nothingHere: UIView!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    // MARK: Toolbar
    let toolbar = UIToolbar()
    let addPostButton = UIButton()
    var sortButton: UIBarButtonItem!
    func createToolbar() {
        followButton = UIBarButtonItem(title: "Follow", style: .Done, target: self, action: #selector(HashtagViewController.toggleFollowing))
        sortButton = UIBarButtonItem(title: "Most recent", style: .Plain, target: nil, action: nil)
        // followButton = UIBarButtonItem(unborderedWithTitle: "Follow", target: self, action: #selector(HashtagViewController.toggleFollowing))
        toolbar.setItems([followButton, sortButton], animated: false)
        view.addSubview(toolbar)
        addPostButton.setImage(UIImage(named: "AddPost"), forState: .Normal)
        addPostButton.addTarget(self, action: #selector(HashtagViewController.addPost), forControlEvents: .TouchUpInside)
        view.addSubview(addPostButton)
    }
    
    // MARK: Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolbar.frame = CGRectMake(0, view.bounds.size.height - 44, view.bounds.width, 44)
        collectionView.frame = CGRectMake(0, 0, view.bounds.width, toolbar.frame.minY)
        addPostButton.sizeToFit()
        addPostButton.center = CGPointMake(view.bounds.width - addPostButton.frame.width/2 - 10, toolbar.frame.minY - 10)
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
            editor.onPrePost = {
                [weak self] in
                if let s = self {
                    Data.setFollowing(s.hashtag, following: true, isUser: false)
                }
            }
            editor.onPost = {
                [weak self] (cardID: String) in
                delay(0.5, closure: { 
                    self?.collectionView.setContentOffset(CGPointMake(0, -(self?.collectionView.contentInset.top ?? 0)), animated: true)
                })
            }
        }
    }
    
    // MARK: Info
    var ownerName: String?
    var ownerIsSelf: Bool?
    var hashtagDescription: String?
    var _infoSub: Subscription?
    var _ownersSub: Subscription?
    func _updateGroupInfo() {
        let attrs: [String: AnyObject] = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.systemFontOfSize(14)]
        var underlinedAttrs = attrs
        underlinedAttrs[NSUnderlineStyleAttributeName] = NSUnderlineStyle.StyleSingle.rawValue
        
        let text = NSMutableAttributedString()
        if let n = ownerName {
            text.appendAttributedString(NSAttributedString(string: "Created by \(n)", attributes: attrs))
        }
        if let desc = hashtagDescription {
            text.appendAttributedString(NSAttributedString(string: ":\n" + desc, attributes: attrs))
        }
        if ownerIsSelf ?? false {
            text.appendAttributedString(NSAttributedString(string: "\nEdit group info", attributes: underlinedAttrs))
        }
        
        let p = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        p.alignment = NSTextAlignment.Left
        text.addAttribute(NSParagraphStyleAttributeName, value: p, range: NSMakeRange(0, text.length))
        
        groupInfoRow = RowModel.Caption(text: text, action: {
            [weak self] in
            self?.editGroupInfo()
        })
    }
    
    var groupInfoRow: RowModel? {
        didSet {
            _updateRows()
        }
    }
    
    @IBAction func editGroupInfo() {
        if ownerIsSelf ?? false {
            // TODO
        }
    }
}

