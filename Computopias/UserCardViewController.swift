//
//  UserCardViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/30/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class UserCardViewController: CardFeedViewController {
    var userID: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        followToggle = UIBarButtonItem(title: "Follow", style: .Plain, target: self, action: #selector(UserCardViewController.toggleFollowing))
        _followingSub = Data.isFollowingItem(userID).subscribe({ [weak self] (let following) in
            self?.currentlyFollowing = following
        })
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
        toolbarItems = [followToggle]
    }
    var currentlyFollowing: Bool? {
        didSet {
            followToggle.title = currentlyFollowing ?? false ? "Following" : "Follow"
        }
    }
    var followToggle: UIBarButtonItem!
    var _followingSub: Subscription?
    func toggleFollowing() {
        if let f = currentlyFollowing {
            Data.setFollowing(userID, following: !f, isUser: true)
        }
    }
}

