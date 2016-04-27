//
//  ActivityFeedSource.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

class ActivityFeedSource: NSObject {
    override init() {
        super.init()
        loginUpdated()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ActivityFeedSource.loginUpdated), name: Data.LoginDidCompleteNotification, object: nil)
        _ensureRandomPosts()
        timer = NSTimer(timeInterval: 5 * 60, target: self, selector: #selector(ActivityFeedSource._ensureRandomPosts), userInfo: nil, repeats: true)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    var timer: NSTimer!
    
    func loginUpdated() {
        if Data.getUID() != nil {
            let q = Data.firebase.childByAppendingPath("inboxes").childByAppendingPath(Data.getUID()).queryOrderedByKey().queryLimitedToLast(80)
            _inboxSub = q.snapshotPusher.subscribe({ [weak self] (let snapshotOpt) in
                if let snapshot = snapshotOpt {
                    self?._inboxUpdated(snapshot.childDictionaries)
                }
                })
        }
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
    var _activityCards: [[String: AnyObject]]? {
        didSet {
            _updateCards()
        }
    }
    var _randomCards: [[String: AnyObject]]? {
        didSet {
            _updateCards()
        }
    }
    var fullyLoaded: Bool {
        get {
            return _activityCards != nil && _randomCards != nil
        }
    }
    func _updateCards() {
        _updateGroupsList()
        
        if let a = _activityCards, let r = _randomCards {
            let cards = a + r
            cardIDs.removeAll()
            cardsByID.removeAll()
            var seenCards = Set<String>()
            for card in cards {
                let id = card["cardID"] as! String
                if !seenCards.contains(id) {
                    seenCards.insert(id)
                    cardIDs.append(id)
                    cardsByID[id] = card
                }
            }
        }
    }
    
    var cardIDs = [String]()
    var cardsByID = [String: [String: AnyObject]]()
    
    // MARK: Group lists
    class Model: Equatable {
        var title: String!
        var subtitle: String!
        var route: Route!
        var cardID: String?
    }
    let groupsListModels = Observable<[Model]>(val: [])
    func _updateGroupsList() {
        struct HashtagInfo {
            let hashtag: String
            let date: NSDate
            var names = [String]()
            var namesSet = Set<String>()
            var anyCard: String?
            func toModel() -> Model {
                let m = Model()
                m.title = "#" + hashtag
                m.subtitle = names.joinWithSeparator(", ") + " posted • " + NSDateFormatter.localizedStringFromDate(date, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
                m.route = Route.Hashtag(name: hashtag)
                m.cardID = anyCard
                return m
            }
        }
        var hashtags = [String]()
        var hashtagInfo = [String: HashtagInfo]()
        if let a = _activityCards, let r = _randomCards {
            for card in a + r {
                if let tag = card["hashtag"] as? String,
                    let poster = card["poster"] as? [String: AnyObject],
                    let name = poster["name"] as? String,
                    let date = card["date"] as? Double,
                    let cardID = card["cardID"] as? String {
                    if hashtagInfo[tag] == nil {
                        hashtags.append(tag)
                        hashtagInfo[tag] = HashtagInfo(hashtag: tag, date: NSDate.init(timeIntervalSince1970: date), names: [], namesSet: Set<String>(), anyCard: cardID)
                    }
                    if !hashtagInfo[tag]!.namesSet.contains(name) {
                        hashtagInfo[tag]!.namesSet.insert(name)
                        hashtagInfo[tag]!.names.append(name)
                    }
                }
            }
            groupsListModels.val = hashtags.map({ hashtagInfo[$0]!.toModel() })
        }
    }
}

func ==(lhs: ActivityFeedSource.Model, rhs: ActivityFeedSource.Model) -> Bool {
    return lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.route.url == rhs.route.url && lhs.cardID == rhs.cardID
}
