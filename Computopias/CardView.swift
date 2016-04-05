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
    var poster: String?
    
    let backgroundImageView = UIImageView()
    
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
        
        poster = (j["poster"] as? [String: AnyObject])?["uid"] as? String

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
        drawingView.item = drawingItem
    }
    
    static let CardSize = CGSize(width: 300, height: 400)
    
    var _setupYet = false
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        if !_setupYet {
            _setupYet = true
            
            multipleTouchEnabled = true
            
            insertSubview(backgroundImageView, atIndex: 0)
            
            layer.cornerRadius = CardView.rounding
            clipsToBounds = true
            
            addSubview(ellipsesButton)
            ellipsesButton.setImage(UIImage(named: "ellipses"), forState: .Normal)
            ellipsesButton.addTarget(self, action: #selector(CardView._cardActions(_:)), forControlEvents: .TouchUpInside)
            ellipsesButton.tintColor = UIColor.blackColor()
            ellipsesButton.alpha = 0.7
            
            if drawingView.superview == nil {
                addSubview(drawingView)
            }
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CardView.setNeedsLayout), name: CMWindowGlobalTouchesEndedNotification, object: nil)
        }
    }
    
    static let rounding: CGFloat = 5
    
    // MARK: Grid
    
    var gridCellSize: CGSize {
        get {
            let hCells = Int(floor(CardView.CardSize.width/50))
            let vCells = Int(floor(CardView.CardSize.height/50))
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
        gridSize = CGSizeMake(max(1, gridSize.width), max(1, gridSize.height))
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
    var _outlineRect: UIView?
    func showProposalRectForView(view: CardItemView?) {
        if let v = view {
            if _proposalRect == nil {
                _proposalRect = UIView()
                insertSubview(_proposalRect!, aboveSubview: backgroundImageView)
                _proposalRect!.backgroundColor = UIColor(white: 1, alpha: 0.5)
                _proposalRect!.layer.cornerRadius = CardView.rounding
            }
            if _outlineRect == nil {
                _outlineRect = UIView()
                insertSubview(_outlineRect!, aboveSubview: _proposalRect!)
                _outlineRect!.layer.cornerRadius = CardView.rounding
                _outlineRect!.layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
                _outlineRect!.layer.borderWidth = 1.5
            }
            _proposalRect!.frame = proposedFrameForView(v)
            _outlineRect!.frame = v.frame
        } else {
            _proposalRect?.removeFromSuperview()
            _proposalRect = nil
            _outlineRect?.removeFromSuperview()
            _outlineRect = nil
        }
    }
    
    func frameForHorizontalExpansionOfView(view: CardItemView!) -> CGRect? {
        let fudge: CGFloat = 2
        if view.frame.right + gridCellSize.width <= bounds.size.width + fudge {
            var f = view.frame
            f.size.width += gridCellSize.height
            return f
        } else {
            return nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundImageView.frame = bounds
        
        ellipsesButton.frame = CGRectMake(bounds.size.width - gridCellSize.width, bounds.size.height - gridCellSize.height, gridCellSize.width, gridCellSize.height)
        if ellipsesButton.superview != nil {
            bringSubviewToFront(ellipsesButton)
        }
        drawingView.frame = bounds
        bringSubviewToFront(drawingView)
        
        for item in items {
            if item != editingItem {
                let x = CardItemView.Alignment.fromValues(0, itemMin: item.frame.origin.x, itemMax: item.frame.right, containerMax: bounds.width)
                let y = CardItemView.Alignment.fromValues(0, itemMin: item.frame.origin.y, itemMax: item.frame.bottom, containerMax: bounds.height)
                item.alignment = (x: x, y: y)
            }
        }
    }
    
    // MARK: Card actions
    
    func canDelete() -> Bool {
        return canEdit() && hashtag != "profiles"
    }
    
    func canEdit() -> Bool {
        return poster != nil && poster! == Data.getUID()
    }
    
    let ellipsesButton = UIButton()
    func _cardActions(sender: UIButton) {
        if cardFirebase == nil { return }
        let actions = UIAlertController(title: "Card Actions", message: nil, preferredStyle: .ActionSheet)
        if self.canDelete() {
            actions.addAction(UIAlertAction(title: "Delete card", style: .Destructive, handler: { (_) in
                Data.DeleteCard(self.cardFirebase!.key)
            }))
        }
        if canEdit() {
            actions.addAction(UIAlertAction(title: "Edit card", style: .Default, handler: { (_) in
                self.editCard()
            }))
        }
        actions.addAction(UIAlertAction(title: "Copy direct link", style: .Default, handler: { (let _) in
            if let hashtag = self.hashtag, let key = self.cardFirebase?.key {
                let link = Route.Card(hashtag: hashtag, id: key)
                UIPasteboard.generalPasteboard().string = link.url.absoluteString
            }
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
    
    func editCard() {
        // fetch this card:
        self.cardFirebase?.observeSingleEventOfType(.Value, withBlock: { (let snapshotOpt) in
            if let snapshot = snapshotOpt, let value = snapshot.value as? [String: AnyObject] {
                let editor = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Editor") as! CardEditor
                editor.hashtag = self.hashtag
                editor.existingContent = value
                editor.existingID = self.cardFirebase!.key
                NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(editor, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: Drawing mode
    func startDrawing() {
        drawingView.item = drawingItem // make sure it's set
        drawingView.drawingModeActive = true
        drawingView.onDone = {
            (drawingView) in
            drawingView.drawingModeActive = false
        }
    }
    let drawingView = DrawingView()
    var drawingItem: DrawingCardItemView? {
        get {
            for item in items {
                if let d = item as? DrawingCardItemView {
                    return d
                }
            }
            return nil
        }
    }
    
    // MARK: Gestures
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, withEvent: event)
        if let v = result, let parent = _itemParentOfView(v) where !parent.acceptsTouches() {
            return self // ignore the individual item
        }
        return result
    }
    func _itemParentOfView(view: UIView) -> CardItemView? {
        var v: UIView? = view
        while v != nil {
            if let item = (v as? CardItemView) {
                return item
            } else {
                v = v?.superview
            }
        }
        return nil
    }
    var editingItem: CardItemView? {
        didSet {
            showProposalRectForView(editingItem)
        }
    }
    var _prevTouchRect: CGRect?
    func _nearestItemToPoint(point: CGPoint) -> CardItemView? {
        let smallestDist = items.reverse().map({ $0.frame.distanceFromPoint(point) }).reduce(99999, combine: { $0 < $1 ? $0 : $1 })
        return items.filter({ $0.frame.distanceFromPoint(point) == smallestDist }).first
    }
    var _touchesDown = Set<UITouch>()
    var _tapStartPos: CGPoint?
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if _touchesDown.count == 0 {
            if let item = _nearestItemToPoint(touches.first!.locationInView(self)) where item.templateEditMode {
                editingItem = _nearestItemToPoint(touches.first!.locationInView(self))
            }
            _tapStartPos = touches.first!.locationInView(self)
        } else {
            _tapStartPos = nil
        }
        for t in touches { _touchesDown.insert(t) }
        _prevTouchRect = boundingRectOfTouches(_touchesDown)
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchRect = boundingRectOfTouches(_touchesDown)
        if _tapStartPos != nil && (_tapStartPos! - touches.first!.locationInView(self)).magnitude > 5 {
            _tapStartPos = nil // we've moved too much; no tap
        }
        if let prev = _prevTouchRect {
            let dx = touchRect.center.x - prev.center.x
            let dy = touchRect.center.y - prev.center.y
            let dw = touchRect.size.width - prev.size.width
            let dh = touchRect.size.height - prev.size.height
            if let item = editingItem {
                let newCenter = CGPointMake(item.center.x + dx, item.center.y + dy)
                let newSize = CGSizeMake(item.bounds.size.width + dw, item.bounds.size.height + dh)
                item.frame = CGRectMake(newCenter.x - newSize.width/2, newCenter.y - newSize.height/2, newSize.width, newSize.height)
                showProposalRectForView(item)
            }
        }
        _prevTouchRect = touchRect
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for t in touches { _touchesDown.remove(t) }
        _prevTouchRect = boundingRectOfTouches(_touchesDown)
        if _touchesDown.count == 0 {
            if let item = editingItem {
                if CGRectIntersectsRect(item.frame, bounds) {
                    item.frame = proposedFrameForView(item)
                } else {
                    item.removeFromSuperview() // remove item
                }
            }
            if let pos = _tapStartPos, let tappedItem = _nearestItemToPoint(pos) where CGRectContainsPoint(tappedItem.frame, pos) {
                tappedItem.tapped()
            }
            editingItem = nil
        }
        setNeedsLayout()
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        touchesEnded(touches ?? Set<UITouch>(), withEvent: event)
    }
}

extension UIView {
    func boundingRectOfTouches(touches: Set<UITouch>) -> CGRect! {
        let positions = touches.map({ $0.locationInView(self) })
        if var minPt = positions.first {
            var maxPt = minPt
            for pos in positions {
                minPt.x = min(minPt.x, pos.x)
                minPt.y = min(minPt.y, pos.y)
                maxPt.x = max(maxPt.x, pos.x)
                maxPt.y = max(maxPt.y, pos.y)
            }
            return CGRectMake(minPt.x, minPt.y, maxPt.x - minPt.x, maxPt.y - minPt.y)
        } else {
            return nil
        }
    }
}
