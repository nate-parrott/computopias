//
//  ActivityFeedViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/31/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class ActivityFeedViewController: CardFeedViewController {
    override func startUpdating() {
        super.startUpdating()
        let q = Data.firebase.childByAppendingPath("inboxes").childByAppendingPath(Data.getUID()).queryOrderedByKey().queryLimitedToLast(80)
        _inboxSub = q.snapshotPusher.subscribe({ [weak self] (let snapshotOpt) in
            if let snapshot = snapshotOpt {
                self?._inboxUpdated(snapshot.childDictionaries)
            }
            })
    }
    
    override func stopUpdating() {
        super.stopUpdating()
        _inboxSub = nil
    }
    
    var _inboxSub: Subscription?
    func _inboxUpdated(entries: [[String: AnyObject]]) {
        /*
         ASSEMBLING THE FEED:
         make a list of everything we're following that's represented in the feed
         for each of these, make a list of the relevant cards
         sort each followed item by the most recent relevant card
         loop over this list until there's nothing left
        */
        var cardEntries = entries.filter({ $0["type"] as? String == "card" && ($0["negativeDate"] as? Double) != nil })
        // sort by time descending:
        cardEntries.sortInPlace({ ($0["negativeDate"] as! Double) < ($1["negativeDate"] as! Double) })

        var cards = [[String: AnyObject]]()
        cards = filterCardsByRecency(cards, maxAge: 48 * 24 * 60 * 60)
        var seenCardIDs = Set<String>()
        while cardEntries.count > 0 {
            var entriesForLater = [[String: AnyObject]]()
            var followedItemsSeenThisCycle = Set<String>()
            
            for entry in cardEntries {
                if let card = entry["card"] as? [String: AnyObject], let cardID = card["cardID"] as? String {
                    if seenCardIDs.contains(cardID) { continue }
                    seenCardIDs.insert(cardID)
                    
                    // make sure we haven't shown content from the same sources during this cycle in the feed:
                    var show = false
                    var canShowLater = false
                    for followedItem in _followedItemsFromInboxEntry(entry) {
                        canShowLater = true
                        if !followedItemsSeenThisCycle.contains(followedItem) {
                            show = true
                            followedItemsSeenThisCycle.insert(followedItem)
                        }
                    }
                    if show, let card = entry["card"] as? [String: AnyObject] {
                        cards.append(card)
                    }
                    if !show && canShowLater {
                        entriesForLater.append(entry)
                    }
                }
            }
            
            cardEntries = entriesForLater
        }
        
        _activityCards = cards
    }
    
    override func createRowsForCardDicts(cardDicts: [[String : AnyObject]]) -> [CardFeedViewController.RowModel] {
        var seenCardIDs = Set<String>()
        
        var rows = [RowModel]()
        for card in cardDicts {
            if let cardID = card["cardID"] as? String, let hashtag = card["hashtag"] as? String where !seenCardIDs.contains(cardID) {
                seenCardIDs.insert(cardID)
                let posterName = (card["poster"] as? [String: AnyObject])?["name"] as? String ?? "??"
                let text = NSAttributedString.smallText("\(posterName) in ") + NSAttributedString.smallBoldText(hashtag + " ›")
                rows.append(RowModel.Caption(text: text, action: {
                    [weak self] in
                    self?.navigate(Route.Hashtag(name: hashtag))
                    }))
                rows.append(RowModel.Card(id: cardID, hashtag: hashtag))
            }
        }
        return rows
    }
    
    func filterCardsByRecency(cards: [[String: AnyObject]], maxAge: NSTimeInterval) -> [[String: AnyObject]] {
        let now = NSDate().timeIntervalSince1970
        return cards.filter({
            (let card) in
            if let negativeDate = card["negativeDate"] as? NSTimeInterval {
                let age = now - (-negativeDate)
                return age < maxAge
            } else {
                return false
            }
        })
    }
        
    func _followedItemsFromInboxEntry(entry: [String: AnyObject]) -> [String] {
        var followedItemsForCard = [String]()
        if let card = entry["card"] as? [String: AnyObject] {
            if let hashtag = card["hashtag"] as? String {
                followedItemsForCard.append(hashtag)
            }
            if let poster = card["poster"] as? [String: AnyObject], let uid = poster["uid"] as? String {
                followedItemsForCard.append(uid)
            }
        }
        return followedItemsForCard
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _ensureRandomPosts()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Data.lastHomeScreenShownWasFriendsList = false
    }
    
    override func getTabs() -> [(String, Route)]? {
        return NavigableViewController.homeTabs()
    }
    
    override var isHome: Bool {
        get {
            return true
        }
    }
    
    // MARK: Random posts
    var _lastLoadedRandomPosts: CFAbsoluteTime?
    func _ensureRandomPosts() {
        let randomPostReloadInterval: CFAbsoluteTime = 60 * 5
        if CFAbsoluteTimeGetCurrent() - (_lastLoadedRandomPosts ?? 0) > randomPostReloadInterval {
            // reload random posts:
            let query = Data.firebase.childByAppendingPath("inboxes").childByAppendingPath("all").queryOrderedByKey().queryLimitedToLast(30)
            query.observeSingleEventOfType(.Value, withBlock: { [weak self] (let snapshot) in
                var cards = [[String: AnyObject]]()
                for entry in snapshot.childDictionaries {
                    if let card = entry["card"] as? [String: AnyObject] {
                        cards.append(card)
                    }
                }
                self?._randomCards = cards
            })
        }
    }
    
    // MARK: Cards and rows
    var _activityCards = [[String: AnyObject]]() {
        didSet {
            _updateRows()
        }
    }
    var _randomCards = [[String: AnyObject]]() {
        didSet {
            _updateRows()
        }
    }
    func _updateRows() {
        rows = createRowsForCardDicts(_activityCards + _randomCards)
    }
}
