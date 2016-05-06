//
//  HashtagCardsViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class HashtagCardsViewController: CardsViewController {
    var hashtag: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "#" + hashtag
        
        followButton = CUButton(title: following ?? false ? "Following" : "Follow", action: { 
            [weak self] in
            self?.toggleFollowing()
        })
        _followingSub = Data.isFollowingItem(hashtag).subscribe({ [weak self] (let following) in
            self?.following = following
        })
        let addPostButton = CUButton(title: "Post") { 
            [weak self] in
            self?.source?.addPost()
        }
        if hashtag != "whatisthis" {
            buttons = [addPostButton, followButton]
        }
    }
    
    override func startUpdating() {
        super.startUpdating()
        source = HashtagFeedSource(hashtag: hashtag)
        _cardsSub = source?.cardIDs.subscribe({ [weak self] (let cardIDs) in
            self?._updateCards()
        })
        _updateCards()
        _groupInfoSub = source?.groupInfoText.subscribe({ [weak self] (let text) in
            self?.descriptionLabel.attributedText = text
            self?.view.setNeedsLayout()
        })
    }
    override func stopUpdating() {
        super.stopUpdating()
        source = nil
        _cardsSub = nil
        _groupInfoSub = nil
    }
    var source: HashtagFeedSource?
    var _cardsSub: Subscription?
    func _updateCards() {
        var items = [Item]()
        for id in source!.cardIDs.val {
            if let card = source!.cardsByID[id] {
                if let model = CardItem(dict: card, vc: self) {
                    items.append(model)
                }
            }
        }
        modelItems = items
    }
    // MARK: Following
    var following: Bool? {
        didSet {
            followButton.setTitle(following ?? false ? "Following" : "Follow", forState: .Normal)
            view.setNeedsLayout()
        }
    }
    var _followingSub: Subscription?
    var followButton: CUButton!
    
    func toggleFollowing() {
        Data.setFollowing(hashtag, following: !(following ?? false), type: .Hashtag)
    }
    
    // MARK: Group info
    var _groupInfoSub: Subscription?
    override func tappedDescriptionLabel() {
        super.tappedDescriptionLabel()
        source?.editGroupInfo()
    }
}
