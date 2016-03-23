//
//  CardView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardView: UIView {
    var items: [CardItemView] {
        get {
            return subviews.filter({ ($0 as? CardItemView) != nil }).map({ $0 as! CardItemView })
        }
    }
    func toJson() -> [String: AnyObject] {
        var j = [String: AnyObject]()
        j["width"] = "\(bounds.size.width)"
        j["height"] = "\(bounds.size.height)"
        j["items"] = items.map({ $0.toJson() })
        return j
    }
    
    func importJson(j: [String: AnyObject]) {
        /*if let w = j["width"] as? String, let h = j["height"] as? String, let wf = Float(w), let hf = Float(h) {
            bounds = CGRectMake(0, 0, CGFloat(wf), CGFloat(hf))
        }*/
        
        for item in items {
            item.removeFromSuperview()
        }
        
        if let items = j["items"] as? [[String: AnyObject]] {
            for item in items {
                if let itemView = CardItemView.FromJson(item) {
                    addSubview(itemView)
                }
            }
        }
    }
    
    static let CardSize = CGSize(width: 300, height: 400)
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        layer.cornerRadius = 5
    }
}
