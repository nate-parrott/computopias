//
//  ProfileViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ProfileViewController: CardsViewController {
    var userID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        followButton = CUButton(title: "", action: { 
            [weak self] in
            self?.toggleFollowing()
        })
        if userID != Data.getUID() {
            buttons = [followButton]
        }
    }
    var followButton: CUButton!
    
    var _activitySub: Subscription?
    var _userInfoSub: Subscription?
    var _followingSub: Subscription?
    
    override func startUpdating() {
        super.startUpdating()
        _activitySub = Data.firebase.childByAppendingPath("outboxes").childByAppendingPath(userID).queryLimitedToLast(50).snapshotPusher.subscribe({ [weak self] (let snapshot) in
            if let s = snapshot {
                self?.activityCards = Array(s.childDictionaries.reverse())
            }
        })
        _userInfoSub = Data.firebase.childByAppendingPath("users").childByAppendingPath(userID).pusher.subscribe({ [weak self] (let d) in
            self?.userInfo = d as? [String: AnyObject]
        })
        _followingSub = Data.isFollowingItem(userID).subscribe({ [weak self] (let following) in
            self?.isFollowing = following
        })
    }
    
    override func stopUpdating() {
        super.stopUpdating()
        _activitySub = nil
        _userInfoSub = nil
        _followingSub = nil
    }
    
    var userInfo: [String: AnyObject]? {
        didSet {
            if let name = userInfo?["name"] as? String {
                title = name
            }
        }
    }
    
    var activityCards = [[String: AnyObject]]() {
        didSet {
            var m = [Item]()
            for dict in activityCards {
                if dict["type"] as? String == "card", let cardDict = dict["card"] as? [String: AnyObject] {
                    if let c = CardItem(dict: cardDict, vc: self) {
                        m.append(c)
                    }
                }
            }
            modelItems = m
        }
    }
    
    var isFollowing: Bool? {
        didSet {
            if let f = isFollowing {
                followButton.setTitle(f ? "Following" : "Follow", forState: .Normal)
                buttons = []
                buttons = [followButton]
            }
        }
    }
    
    func toggleFollowing() {
        if let f = isFollowing {
            Data.setFollowing(userID, following: !f, type: .User)
        }
    }
}
