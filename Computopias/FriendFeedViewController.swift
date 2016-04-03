//
//  FriendFeedViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/29/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class FriendFeedViewController: CardFeedViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "addFriends"), style: .Plain, target: self, action: #selector(FriendFeedViewController.addFriends))
    }
    
    override func startUpdating() {
        var rows = [RowModel]()
        if let profile = Data.profileFirebase() {
            let text = NSAttributedString.smallText("This is your profile. Try ") + NSAttributedString.smallUnderlinedText("editing it") + NSAttributedString.defaultText(".")
            rows.append(RowModel.Caption(text: text, action: {
                [weak self] in
                self?.cellForCardWithID(profile.key)?.cardView.editCard()
                }))
            rows.append(RowModel.Card(id: profile.key, hashtag: "profiles"))
        }
        self.selfProfileRows = rows
        
        if Data.getUID() != nil {
            _friendsListSub = Data.friendFeed().subscribe({ [weak self] (let friendIDs) in
                self?.friendRows = friendIDs.map({ CardFeedViewController.RowModel.Card(id: $0, hashtag: "profiles") })
                })
        }
    }
    
    override func stopUpdating() {
        _friendsListSub = nil
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
                            Data.setFollowing(s.key, following: true, isUser: true)
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
    
    // MARK: Friends
    var _friendsListSub: Subscription?
    var friendRows = [RowModel]() {
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
        var r = selfProfileRows
        if friendRows.count > 0 {
            let header = RowModel.Caption(text: NSAttributedString.smallText("People you follow"), action: nil)
            r.append(header)
            r += friendRows
        } else {
            // TODO: show contacts-syncing rows
            if _searchingContactsInProgress {
                let row = RowModel.Caption(text: NSAttributedString.smallText("⏳ Searching for friends"), action: nil)
                r.append(row)
            } else if Data.shouldPromptToDoContactSync() {
                let row = RowModel.Caption(text: NSAttributedString.smallText("No friends to show. ") + NSAttributedString.smallUnderlinedText("Search your contacts") + NSAttributedString.defaultText(" for friends?"), action: {
                    [weak self] in
                    self?._doContactsSync()
                })
                r.append(row)
            } else {
                r.append(RowModel.Caption(text: NSAttributedString.smallText("No friends 😕"), action: nil))
            }
        }
        rows = r
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
