//
//  CardStack.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardStack {
    init() {
        
    }
    let padding: CGFloat = 6
    var cardModels = [String]()
    func createCard(model: String) -> UIView {
        return UIView()
    }
    func renderCard(model: String, view: UIView) {
        
    }
    var backgroundColor = UIColor.whiteColor()
    var title: String?
    var identifier = NSUUID().UUIDString
    var visible = false {
        didSet {
            if visible != oldValue {
                if visible {
                    becameVisible()
                } else {
                    noLongerVisible()
                }
            }
        }
    }
    func becameVisible() {
        
    }
    func noLongerVisible() {
        
    }
    func renderTopControls(view: UIView, rect: CGRect) {
        
    }
    func renderBottomControls(view: UIView, rect: CGRect) {
        
    }
    
    weak var navigator: CardNavigatorView?
    
    func navigate(route: Route) {
        if let stack = CardStack.FromRoute(route) {
            navigator?.pushCardStack(stack, above: self)
        }
    }
    
    class func FromRoute(route: Route) -> CardStack? {
        switch route {
        case .Activity:
            return ActivityCardStack()
        case .Hashtag(name: let hashtag):
            let s = HashtagCardStack()
            s.hashtag = hashtag
            return s
        default:
            return nil // TODO: individual cards
        }
    }
}

class FakeCardStack: CardStack {
    override init() {
        super.init()
        for datum in EVFakeData.getFakeData(10) {
            data[datum.identifier] = datum
        }
        cardModels = Array(data.keys)
    }
    override func createCard(model: String) -> UIView {
        return UILabel()
    }
    var data = [String: EVFakeData]()
    override func renderCard(model: String, view: UIView) {
        let label = view as! UILabel
        let datum = data[model]!
        label.backgroundColor = datum.color
        label.text = datum.shortText
        label.textAlignment = .Center
        label.layer.cornerRadius = 10
        label.numberOfLines = 0
    }
}