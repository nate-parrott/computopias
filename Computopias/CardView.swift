//
//  CardView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase
import AsyncDisplayKit

class CardView: ASDisplayNode {
    override init() {
        super.init()
        setup()
    }
    
    var cardFirebase: Firebase? {
        didSet (old) {
            if cardFirebase != old {
                setNeedsDisplay()
                taggingView?.cardFirebase = cardFirebase
            }
        }
    }
    var hashtag: String?
    var poster: String?
    var posterName: String?
    
    let importJsonQueue = dispatch_queue_create("CardViewImportJson", nil)
        
    var onTap: (() -> ())?
    
    var items: [CardItemView] {
        get {
            return itemsNode.subnodes.filter({ ($0 as? CardItemView) != nil }).map({ $0 as! CardItemView })
        }
    }
    
    func toJson() -> [String: AnyObject] {
        var j = [String: AnyObject]()
        j["width"] = "\(bounds.size.width)"
        j["height"] = "\(bounds.size.height)"
        j["items"] = items.map({ $0.toJson() })
        return j
    }
    
    func importJson(j: [String: AnyObject], callback: (() -> ())?) {
        /*if let w = j["width"] as? String, let h = j["height"] as? String, let wf = Float(w), let hf = Float(h) {
            bounds = CGRectMake(0, 0, CGFloat(wf), CGFloat(hf))
        }*/
        
        if let posterDict = j["poster"] as? [String: AnyObject] {
            poster = posterDict["uid"] as? String
            posterName = posterDict["name"] as? String
        }
        
        if let cardHashtag = j["hashtag"] as? String {
            hashtag = cardHashtag
        }
        
        if let tagsDict = j["tags"] as? [String: [String: AnyObject]] {
            tags = Array(tagsDict.values)
        } else {
            tags = []
        }
        
        let createItems: () -> () = {
            let itemsNode = ASDisplayNode()
            itemsNode.frame = CGRectMake(0, 0, CardView.CardSize.width, CardView.CardSize.height)
            
            let items = j["items"] as? [[String: AnyObject]] ?? [[String: AnyObject]]()
            if items != self._itemsJson {
                self._itemsJson = items
                for item in items {
                    if let itemView = CardItemView.FromJson(item) {
                        itemsNode.addSubnode(itemView)
                    }
                }
                
                mainThread({
                    self.itemsNode = itemsNode
                    self.drawingView.item = self.drawingItem
                })
            }
            
            self._hideIfBlocked()
            
            mainThread({
                if let cb = callback { cb() }
            })
        }
        
        dispatch_async(importJsonQueue, createItems)
    }
    var _itemsJson = [[String: AnyObject]]()
    
    func presentJson(json: [String: AnyObject]) {
        importJson(json) {
            for item in self.items ?? [] {
                item.prepareToPresent()
            }
        }
    }
    
    static let CardSize = CGSize(width: 300, height: 400)
    
    func setup() {
        addSubnode(itemsNode)
        opaque = false
        _loadAuxiliaryViewsInBackground()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CardView._hideIfBlocked), name: Data.BlockedUsersChangedNotification, object: nil)
    }
    
    override func didLoad() {
        super.didLoad()
        view.multipleTouchEnabled = true
        // exclusiveTouch = true
    }
    
    var itemsNode = ASDisplayNode() {
        didSet {
            oldValue.removeFromSupernode()
            insertSubnode(itemsNode, atIndex: 0)
        }
    }
    
    static let rounding: CGFloat = 5
    
    // MARK: Grid
    
    class var gridCellSize: CGSize {
        get {
            let hCells = Int(floor(CardView.CardSize.width/50))
            let vCells = Int(floor(CardView.CardSize.height/50))
            return CGSizeMake(CardView.CardSize.width / CGFloat(hCells), CardView.CardSize.height / CGFloat(vCells))
        }
    }
    var gridCellSize: CGSize {
        get {
            return CardView.gridCellSize
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
    
    var _proposalRect: ASDisplayNode?
    var _outlineRect: ASDisplayNode?
    func showProposalRectForView(view: CardItemView?) {
        if let v = view {
            if _proposalRect == nil {
                _proposalRect = ASDisplayNode()
                insertSubnode(_proposalRect!, atIndex: 0)
                _proposalRect!.backgroundColor = UIColor(white: 1, alpha: 0.5)
                _proposalRect!.layer.cornerRadius = CardView.rounding
            }
            if _outlineRect == nil {
                _outlineRect = ASDisplayNode()
                insertSubnode(_outlineRect!, aboveSubnode: _proposalRect!)
                _outlineRect!.cornerRadius = CardView.rounding
                _outlineRect!.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
                _outlineRect!.borderWidth = 1.5
            }
            _proposalRect!.frame = proposedFrameForView(v)
            _outlineRect!.frame = v.frame
        } else {
            _proposalRect?.removeFromSupernode()
            _proposalRect = nil
            _outlineRect?.removeFromSupernode()
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
    
    override func layout() {
        super.layout()
        itemsNode.frame = bounds
        
        taggingView?.frame = bounds
        
        if _auxiliaryViewsLoaded {
            ellipsesButton.frame = CGRectMake(bounds.size.width - gridCellSize.width, bounds.size.height - gridCellSize.height, gridCellSize.width, gridCellSize.height)
            if ellipsesButton.supernode != nil {
                // bringSubviewToFront(ellipsesButton)
            }
            drawingView.frame = bounds
            // bringSubviewToFront(drawingView)
        }
        
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
    
    func _cardActions(sender: UIButton) {
        if cardFirebase == nil { return }
        let actions = UIAlertController(title: "Card Actions", message: nil, preferredStyle: .ActionSheet)
        actions.addAction(UIAlertAction(title: "Tag Friends", style: .Default, handler: { (_) in
            self.ensureTaggingView().tagMode = true
        }))
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
        actions.addAction(UIAlertAction(title: "Flag or block", style: .Default, handler: { (let _) in
            self.showFlagDialog()
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
    
    // MARK: AuxiliaryViews
    var _auxiliaryViewsLoaded = false
    func _loadAuxiliaryViewsInBackground() {
        backgroundThread {
            let drawing = self.drawingView // instantiate the lazy prop
            let e = self.ellipsesButton
            e.userInteractionEnabled = true
            e.image = UIImage(named: "ellipses")
            e.contentMode = .Center
            e.addTarget(self, action: #selector(CardView._cardActions(_:)), forControlEvents: .TouchUpInside)
            e.tintColor = UIColor.blackColor()
            e.alpha = 0.7
            mainThread({
                self.addSubnode(drawing)
                self.addSubnode(e)
                self._auxiliaryViewsLoaded = true
            })
        }
    }
    lazy var ellipsesButton: ASImageNode = {
        return ASImageNode()
    }()
    lazy var drawingView: DrawingView = {
        let v = DrawingView()
        return v
    }()
    
    // MARK: Drawing mode
    func startDrawing() {
        drawingView.item = drawingItem // make sure it's set
        drawingView.drawingModeActive = true
        drawingView.onDone = {
            (drawingView) in
            drawingView.drawingModeActive = false
        }
    }
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
    
    // MARK: Tagging mode
    var taggingView: TaggingOverlayView?
    func ensureTaggingView() -> TaggingOverlayView {
        if taggingView == nil {
            taggingView = TaggingOverlayView()
            taggingView?.cardFirebase = cardFirebase
            addSubnode(taggingView!)
        }
        return taggingView!
    }
    var tags = [[String: AnyObject]]() {
        didSet {
            if tags.count == 0 {
                if let t = taggingView {
                    t.tags = []
                }
            } else {
                ensureTaggingView().tags = tags
            }
        }
    }
    
    // MARK: Gestures
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, withEvent: event)
        if let v = result, let parent = _itemParentOfView(v) {
            if parent.userInteractionEnabled {
                return result
            } else {
                return self.view // ignore the individual item
            }
        }
        if result == itemsNode.view {
            return self.view
        }
        return result
    }
    func _itemParentOfView(view: UIView) -> UIView? {
        var v: UIView? = view
        while v != nil {
            if v!.superview == itemsNode.view {
                return v
            } else {
                v = v!.superview
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
        let smallestDist = items.map({ $0.frame.distanceFromPoint(point) }).reduce(99999, combine: { $0 < $1 ? $0 : $1 })
        return items.reverse().filter({ $0.frame.distanceFromPoint(point) == smallestDist }).first
    }
    var _touchesDown = Set<UITouch>()
    var _tapStartPos: CGPoint?
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if _touchesDown.count == 0 {
            if let item = _nearestItemToPoint(touches.first!.locationInView(self.view)) where item.templateEditMode {
                editingItem = _nearestItemToPoint(touches.first!.locationInView(self.view))
            }
            _tapStartPos = touches.first!.locationInView(self.view.window!)
        } else {
            _tapStartPos = nil
        }
        for t in touches { _touchesDown.insert(t) }
        _prevTouchRect = boundingRectOfTouches(_touchesDown)
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchRect = boundingRectOfTouches(_touchesDown)
        if _tapStartPos != nil && (_tapStartPos! - touches.first!.locationInView(self.view.window!)).magnitude > 5 {
            _tapStartPos = nil // we've moved too much; no tap
        }
        if let prev = _prevTouchRect {
            let dx = touchRect.center.x - prev.center.x
            let dy = touchRect.center.y - prev.center.y
            let dw = touchRect.size.width - prev.size.width
            let dh = touchRect.size.height - prev.size.height
            if let item = editingItem {
                let newCenter = CGPointMake(item.position.x + dx, item.position.y + dy)
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
                    item.removeFromSupernode() // remove item
                }
            }
            if let pos = _tapStartPos {
                var handledTap = false
                let posInViewCoords = view.convertPoint(pos, fromView: view.window!)
                if let tappedItem = _nearestItemToPoint(posInViewCoords) where CGRectContainsPoint(tappedItem.frame, posInViewCoords) {
                    let tapPoint = tappedItem.convertPoint(posInViewCoords, fromNode: self)
                    let tapInfo = CardItemView.TapInfo(position: tapPoint)
                    handledTap = tappedItem.tapped(tapInfo)
                }
                if let t = onTap where !handledTap {
                    t()
                }
            }
            editingItem = nil
        }
        setNeedsLayout()
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        _tapStartPos = nil
        touchesEnded(touches ?? Set<UITouch>(), withEvent: event)
    }
    // MARK: Drawing
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        opaque = false
        return cardFirebase?.key ?? "" as NSString
        // return (hashtag ?? "") + (cardFirebase?.key ?? "") as NSString
    }
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let string = withParameters as! NSString
        let gradient = Appearance.gradientForString(string as String)
        UIBezierPath(roundedRect: bounds, cornerRadius: CardView.rounding).addClip()
        gradient.drawInRect(bounds)
    }
}

extension ASDisplayNode {
    func boundingRectOfTouches(touches: Set<UITouch>) -> CGRect! {
        let positions = touches.map({ $0.locationInView(self.view) })
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
