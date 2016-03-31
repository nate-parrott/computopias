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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FriendFeedViewController._loginChanged), name: Data.LoginDidCompleteNotification, object: nil)
        _loginChanged(nil)
    }
    
    func _loginChanged(sender: AnyObject!) {
        print("Logged in as \(Data.getName())")
        
        var rows = [RowModel]()
        if let profile = Data.profileFirebase() {
            let text = NSAttributedString.defaultText("This is your profile. Try ") + NSAttributedString.defaultUnderlinedText("editing it") + NSAttributedString.defaultText(".")
            rows.append(RowModel.Caption(text: text, action: {
                [weak self] in
                self?.cellForCardWithID(profile.key)?.cardView.editCard()
                }))
            rows.append(RowModel.Card(id: profile.key, hashtag: "profiles"))
        }
        self.selfProfileRows = rows
        
        _friendsListSub = Data.friendFeed().subscribe({ [weak self] (let friendIDs) in
            self?.friendRows = friendIDs.map({ CardFeedViewController.RowModel.Card(id: $0, hashtag: "profiles") })
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
    
    // MARK: Rows
    func _updateRows() {
        var r = selfProfileRows
        if friendRows.count > 0 {
            let header = RowModel.Caption(text: NSAttributedString.defaultText("People you follow"), action: nil)
            r.append(header)
            r += friendRows
        } else {
            // TODO: show contacts-syncing rows
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
