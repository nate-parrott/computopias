//
//  ActivityCardStack.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ActivityCardStack: CardFeedStack {
    var source: ActivityFeedSource?
    
    override func becameVisible() {
        super.becameVisible()
        title = "Activity"
        source = ActivityFeedSource()
    }
    
    override func noLongerVisible() {
        super.noLongerVisible()
        source = nil
    }
    
    override var cardModels: [String] {
        get {
            if Data.getUID() == nil {
                return []
            } else {
                return ["HashtagListView"] + super.cardModels
            }
        }
        set {}
    }
    
    override func cardIDs() -> [String] {
        return (source?.cardIDs ?? [])
    }
    
    override func createCard(model: String) -> UIView {
        if model == "HashtagListView" {
            let v = HashtagListView()
            v.onNavigate = {
                [weak self] (route: Route) in
                self?.navigate(route)
            }
            return v
        } else {
            let v = CardViewWrapper()
            v.cardView.onTap = {
                [weak self, weak v] in
                if let (_, hashtag) = v?.card where hashtag != nil {
                    self?.navigate(Route.Hashtag(name: hashtag!))
                }
            }
            return v
        }
    }
    
    override func renderCard(model: String, view: UIView) {
        if model == "HashtagListView" {
            // nothing
        } else {
            super.renderCard(model, view: view)
        }
    }
    
    override func cardDictForID(id: String) -> [String : AnyObject]? {
        return source?.cardsByID[id] ?? nil
    }
    
    override func renderBottomControls(view: UIView, rect: CGRect) {
        let button = view.elasticGetChildWithKey("friends") { () -> UIView! in
            return CUButton(title: "Friends", action: {
                // TODO
            })
            } as! CUButton
        button.sizeToFit()
        button.center = rect.center
    }
    
    override func createCardLabel(hashtag: String, posterName: String, date: Double) -> NSAttributedString {
        return NSAttributedString.smallText(posterName + " in ") + NSAttributedString.smallBoldText(hashtag)
    }
}
