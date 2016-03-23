//
//  CardView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class CardView: UIView {
    var cardFirebase: Firebase?
    var hashtag: String?
    
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
        layer.cornerRadius = CardView.rounding
        
        addSubview(ellipsesButton)
        ellipsesButton.setImage(UIImage(named: "ellipses"), forState: .Normal)
        ellipsesButton.addTarget(self, action: #selector(CardView._cardActions(_:)), forControlEvents: .TouchUpInside)
        ellipsesButton.tintColor = UIColor.blackColor()
        ellipsesButton.alpha = 0.7
    }
    
    static let rounding: CGFloat = 5
    
    // MARK: Grid
    
    var gridCellSize: CGSize {
        get {
            let hCells = Int(floor(CardView.CardSize.width/42))
            let vCells = Int(floor(CardView.CardSize.height/42))
            return CGSizeMake(CardView.CardSize.width / CGFloat(hCells), CardView.CardSize.height / CGFloat(vCells))
        }
    }
    
    func proposedFrameForView(view: CardItemView) -> CGRect {
        if !CGRectIntersectsRect(bounds, view.frame) {
            return CGRectZero
        }
        
        let cellsWide = bounds.size.width / gridCellSize.width;
        let cellsHigh = bounds.size.height / gridCellSize.height
        
        var gridSize = CGSizeMake(round(view.frame.size.width / gridCellSize.width), round(view.frame.size.height / gridCellSize.height))
        gridSize = view.constrainedSizeForProposedSize(gridSize)
        var gridOrigin = CGPointMake(round(view.frame.origin.x / gridCellSize.width), round(view.frame.origin.y / gridCellSize.height))
        while gridOrigin.x + gridSize.width > cellsWide {
            gridOrigin.x -= 1
        }
        while gridOrigin.y + gridSize.height > cellsHigh {
            gridOrigin.y -= 1
        }
        while gridOrigin.x < 0 {
            gridOrigin.x += 1
        }
        while gridOrigin.y < 0 {
            gridOrigin.y += 1
        }
        
        let rect = CGRectMake(gridOrigin.x * gridCellSize.width, gridOrigin.y * gridCellSize.height, gridSize.width * gridCellSize.width, gridSize.height * gridCellSize.height)
        return CGRectIntegral(rect)
    }
    
    var _proposalRect: UIView?
    func showProposalRectForView(view: CardItemView?) {
        if let v = view {
            if _proposalRect == nil {
                _proposalRect = UIView()
                insertSubview(_proposalRect!, atIndex: 0)
                _proposalRect!.backgroundColor = UIColor(white: 1, alpha: 0.5)
                _proposalRect!.layer.cornerRadius = CardView.rounding
            }
            _proposalRect!.frame = proposedFrameForView(v)
        } else {
            _proposalRect?.removeFromSuperview()
            _proposalRect = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ellipsesButton.frame = CGRectMake(bounds.size.width - gridCellSize.width, bounds.size.height - gridCellSize.height, gridCellSize.width, gridCellSize.height)
        if ellipsesButton.superview != nil {
            bringSubviewToFront(ellipsesButton)
        }
    }
    
    // MARK: Card actions
    let ellipsesButton = UIButton()
    func _cardActions(sender: UIButton) {
        if cardFirebase == nil { return }
        let actions = UIAlertController(title: "Card Actions", message: nil, preferredStyle: .ActionSheet)
        actions.addAction(UIAlertAction(title: "Delete card", style: .Destructive, handler: { (_) in
            // TODO
        }))
        actions.addAction(UIAlertAction(title: "Copy direct link", style: .Default, handler: { (let _) in
            if let hashtag = self.hashtag, let key = self.cardFirebase?.key {
                let link = "#\(hashtag)/\(key)"
                UIPasteboard.generalPasteboard().string = link
            }
        }))
        actions.addAction(UIAlertAction(title: "Edit card", style: .Default, handler: { (_) in
            // TODO
        }))
        actions.addAction(UIAlertAction(title: "Never mind", style: .Cancel, handler: { (_) in
            
        }))
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(actions, animated: true, completion: nil)
    }
    
    func blackOut() {
        UIView.animateWithDuration(0.2, delay: 0, options: [.AllowUserInteraction], animations: { 
            for item in self.items {
                item.alpha = 0
            }
            }, completion: nil)
    }
}
