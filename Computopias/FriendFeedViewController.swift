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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FriendFeedViewController._update), name: Data.LoginDidCompleteNotification, object: nil)
        _update(nil)
    }
    
    func _update(sender: AnyObject!) {
        var rows = [RowModel]()
        if let profile = Data.profileFirebase() {
            let text = NSAttributedString.defaultText("This is your profile. Try ") + NSAttributedString.defaultUnderlinedText("editing it") + NSAttributedString.defaultText(".")
            rows.append(RowModel.Caption(text: text, action: {
                [weak self] in
                self?.cellForCardWithID(profile.key)?.cardView.editCard()
            }))
            rows.append(RowModel.Card(id: profile.key, hashtag: "profiles"))
        }
        self.rows = rows
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Data.lastHomeScreenShownWasFriendsList = true
    }
    
    override func getTabs() -> [(String, Route)]? {
        return NavigableViewController.homeTabs()
    }
}
