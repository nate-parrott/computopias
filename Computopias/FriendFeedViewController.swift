//
//  FriendFeedViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/29/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class FriendFeedViewController: CardFeedViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "addFriends"), style: .Plain, target: self, action: #selector(FriendFeedViewController.addFriends))
    }
    
    // MARK: Subscriptions
    var _newFollowersSub: Subscription?
    var _friendsListSub: Subscription?
    
    override func startUpdating() {
        _selfProfile = Data.profileFirebase()
        
        if Data.getUID() != nil {
            _friendsListSub = Data.friendFeed().subscribe({ [weak self] (let friendIDs) in
                self?._friendIDs = friendIDs.filter({ !Data.userIsBlocked($0) }).filter({ $0 != Data.getUID() })
            })
        }
        
        _newFollowersSub = Data.firebase.childByAppendingPath("new_followers").childByAppendingPath(Data.getUID()!).pusher.subscribe({ [weak self] (let dict) in
            if let d = dict as? [String: AnyObject], let followers = Array<AnyObject>(d.values) as? [[String: AnyObject]] {
                self?._newFollowers = followers.filter({ !Data.userIsBlocked($0["uid"] as? String ?? "") })
            } else {
                self?._newFollowers = []
            }
        })
    }
    
    override func stopUpdating() {
        _friendsListSub = nil
        _newFollowersSub = nil
    }
    
    func addFriends() {
        let alert = UIAlertController(title: "Follow Friends", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "📲 Add by phone number", style: .Default, handler: { (_) in
            let q = UIAlertController(title: "Add by phone number", message: nil, preferredStyle: .Alert)
            q.addTextFieldWithConfigurationHandler({ (let field) in
                field.placeholder = "Phone number"
                field.keyboardType = .PhonePad
            })
            q.addAction(UIAlertAction(title: "Never mind", style: .Cancel, handler: nil))
            q.addAction(UIAlertAction(title: "Add", style: .Default, handler: { (_) in
                if let phone = q.textFields?.first?.text?.normalizedPhone where phone != "" {
                    Data.findUserByPhone(phone, callback: { (let snapshot) in
                        if let s = snapshot {
                            self.navigate(Route.forProfile(s.key))
                            Data.setFollowing(s.key, following: true, type: .User)
                        } else {
                            let a = UIAlertController(title: nil, message: "😯 Doesn't look like anyone with the phone number \(phone) has signed up yet.", preferredStyle: .Alert)
                            a.addAction(UIAlertAction(title: "😕 Okay", style: .Default, handler: nil))
                            a.addAction(UIAlertAction(title: "💬 Text them", style: .Default, handler: { (_) in
                                UIApplication.sharedApplication().openURL(NSURL(string: "sms://" + phone)!)
                            }))
                            self.presentViewController(a, animated: true, completion: nil)
                        }
                    })
                }
            }))
            self.presentViewController(q, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "🗃 Search contacts for friends", style: .Default, handler: { (_) in
            self._doContactsSync()
        }))
        alert.addAction(UIAlertAction(title: "Never mind", style: .Cancel, handler: { (_) in
            
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func _doContactsSync() {
        _searchingContactsInProgress = true
        Data.doContactsSync({ (let success) in
            self._searchingContactsInProgress = false
            if !success {
                self.showAlert("Something went wrong 😯")
            }
        })
    }
    
    // MARK: Self-profile
    var selfProfileRows = [RowModel]() {
        didSet {
            _updateRows()
        }
    }
    
    // MARK: Content
    var _friendIDs = [String]() {
        didSet {
            _updateRows()
        }
    }
    var _newFollowers = [[String: AnyObject]]() {
        didSet {
            _updateRows()
        }
    }
    var _selfProfile: Firebase? {
        didSet {
            _updateRows()
        }
    }
    
    var _searchingContactsInProgress = false {
        didSet {
            _updateRows()
        }
    }
    
    // MARK: Rows
    func _updateRows() {
        rows = _createNewFollowersRows() + _createSelfProfileRows() + _createContactsSearchRows() + _createFriendRows()
    }
    
    func _createContactsSearchRows() -> [RowModel] {
        var r = [RowModel]()
        if _friendIDs.count == 0 {
            // TODO: show contacts-syncing rows
            if _searchingContactsInProgress {
                let row = RowModel.Caption(text: NSAttributedString.smallText("⏳ Searching for friends"), action: nil)
                r.append(row)
            } else if Data.shouldPromptToDoContactSync() {
                let row = RowModel.Caption(text: NSAttributedString.smallText("No friends to show. ") + NSAttributedString.smallUnderlinedText("Search your contacts") + NSAttributedString.smallText(" for friends?"), action: {
                    [weak self] in
                    self?._doContactsSync()
                    })
                r.append(row)
            } else {
                r.append(RowModel.Caption(text: NSAttributedString.smallText("No friends 😕"), action: nil))
            }
        }
        return r
    }
    
    func _createNewFollowersRows() -> [RowModel] {
        var r = [RowModel]()
        for follower in _newFollowers {
            if let uid = follower["uid"] as? String, let name = follower["name"] as? String {
                let dismiss = {
                    Data.firebase.childByAppendingPath("new_followers").childByAppendingPath(Data.getUID()!).childByAppendingPath(uid).setValue(nil)
                }
                let follow = { [weak self] in
                    Data.setFollowing(uid, following: true, type: .User)
                    dismiss()
                    self?.navigate(Route.forProfile(uid))
                }
                var buttons = [("Dismiss", dismiss)]
                if !_friendIDs.contains(uid) {
                    buttons = [("Follow", follow)] + buttons
                }
                let row = RowModel.ButtonCell(text: NSAttributedString.smallBoldText(name) + NSAttributedString.smallText(" followed you."), action: { [weak self] in
                    self?.navigate(Route.forProfile(uid))
                    }, buttons: buttons)
                r.append(row)
            }
        }
        return r
    }
    
    func _createSelfProfileRows() -> [RowModel] {
        if let profile = _selfProfile {
            let text = NSAttributedString.smallText("This is your profile. Try ") + NSAttributedString.smallUnderlinedText("editing it") + NSAttributedString.smallText(".")
            let caption = RowModel.Caption(text: text, action: {
                [weak self] in
                self?.cellForCardWithID(profile.key)?.cardView.editCard()
            })
            let profile = RowModel.Card(id: profile.key, hashtag: "profiles")
            return [caption, profile]
        } else {
            return []
        }
    }
    
    func _createFriendRows() -> [RowModel] {
        var r = [RowModel]()
        if _friendIDs.count > 0 {
            let header = RowModel.Caption(text: NSAttributedString.smallText("People you follow"), action: nil)
            r.append(header)
            r += _friendIDs.map({ CardFeedViewController.RowModel.Card(id: $0, hashtag: "profiles") })
        }
        return r
    }
    
    // MARK: Misc.
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Data.lastHomeScreenShownWasFriendsList = true
    }
    
    override func getTabs() -> [(String, Route)]? {
        return NavigableViewController.homeTabs()
    }
    
    override var isHome: Bool {
        get {
            return true
        }
    }
}
