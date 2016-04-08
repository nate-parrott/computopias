//
//  HashtagFeedSource.swift
//  Computopias
//
//  Created by Nate Parrott on 4/8/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

class HashtagFeedSource {
    let hashtag: String
    
    init(hashtag: String) {
        self.hashtag = hashtag
        
        let hashtagFB = Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag)
        
        let q = hashtagFB.childByAppendingPath("cards").queryOrderedByChild("negativeDate").queryLimitedToFirst(50)
        _cardsSub = q.snapshotPusher.subscribe({ [weak self] (let snapshotOpt) in
            if let s = self, let snapshot = snapshotOpt {
                var cardIDs = [String]()
                var cardsByID = [String: [String: AnyObject]]()
                for card in snapshot.childDictionaries {
                    if let id = card["cardID"] as? String {
                        cardIDs.append(id)
                        cardsByID[id] = card
                    }
                }
                s.cardsByID = cardsByID
                s.cardIDs = cardIDs
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
        _updateGroupInfo()
    }
    
    // MARK: Data
    
    var cardIDs = [String]()
    var cardsByID = [String: [String: AnyObject]]()
    
    var _cardsSub: Subscription?
    
    // MARK: Following
    var following: Bool?
    var _followingSub: Subscription?
    
    func toggleFollowing() {
        Data.setFollowing(hashtag, following: !(following ?? false), type: .Hashtag)
    }
    
    // MARK: Posting
    
    @IBAction func addPost() {
        // get the template:
        Data.firebase.childByAppendingPath("templates").childByAppendingPath(hashtag).observeSingleEventOfType(FEventType.Value) { (let snapshot: FDataSnapshot!) -> Void in
            let editor = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Editor") as! CardEditor
            editor.hashtag = self.hashtag
            if let template = snapshot.value as? [String: AnyObject] {
                editor.template = template
            }
            let vc = NPSoftModalPresentationController.getViewControllerForPresentation()
            vc.presentViewController(editor, animated: true, completion: nil)
            editor.onPrePost = {
                [weak self] in
                if let s = self {
                    Data.setFollowing(s.hashtag, following: true, type: .User)
                }
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
        let text = NSMutableAttributedString()
        
        text.appendAttributedString(NSAttributedString.largeText("#" + hashtag + "\n"))
        
        let colon = (hashtagDescription ?? "") != "" ? ":" : ""
        if ownerIsSelf ?? false {
            text.appendAttributedString(NSAttributedString.smallText("Created by you (") + NSAttributedString.smallUnderlinedText("edit") + NSAttributedString.smallText(")" + colon))
        } else if let n = ownerName {
            text.appendAttributedString(NSAttributedString.smallText("Created by \(n)" + colon))
        }
        if let desc = hashtagDescription where desc != "" {
            let trimmed = desc.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            text.appendAttributedString(NSAttributedString.smallText("\n" + trimmed))
        }
        text.addAttributes([NSForegroundColorAttributeName: UIColor(white: 0.1, alpha: 0.5)], range: NSMakeRange(0, text.length))
        groupInfoText = text
    }
    
    var groupInfoText: NSAttributedString?
    
    @IBAction func editGroupInfo() {
        if ownerIsSelf ?? false {
            /*let editor = storyboard!.instantiateViewControllerWithIdentifier("GroupEditor") as! GroupEditor
            editor.hashtag = hashtag
            let nav = UINavigationController(rootViewController: editor)
            presentViewController(nav, animated: true, completion: nil)*/
        }
    }
}
