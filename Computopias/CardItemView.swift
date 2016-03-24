//
//  CardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class CardItemView: UIView, UIGestureRecognizerDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        panRec = UIPanGestureRecognizer(target: self, action: #selector(CardItemView.panned(_:)))
        tapRec = UITapGestureRecognizer(target: self, action: #selector(CardItemView.tapped(_:)))
        pinchRec = UIPinchGestureRecognizer(target: self, action: #selector(CardItemView.pinched(_:)))
        gestureRecs = [panRec, tapRec, pinchRec]
        for r in gestureRecs {
            addGestureRecognizer(r)
            r.delegate = self
        }
    }
    
    var cardPath: Firebase?
    
    var tapRec: UITapGestureRecognizer!
    var panRec: UIPanGestureRecognizer!
    var pinchRec: UIPinchGestureRecognizer!
    
    func setup() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CardItemView._windowTouchedEnded(_:)), name: CMWindowGlobalTouchesEndedNotification, object: nil)
    }
    
    func tapped() {
        
    }
    
    var defaultSize: GridSize {
        return CGSizeMake(2, 1)
    }
    
    func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return defaultSize
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var editMode = true
    var templateEditMode = true {
        didSet {
            panRec.enabled = templateEditMode
        }
    }
    
    var card: CardView? {
        get {
            return superview as? CardView
        }
    }
    
    // MARK: VCs
    
    func presentViewController(vc: UIViewController) {
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(vc, animated: true, completion: nil)
    }
    
    // MARK: Gesture recs
    var gestureRecs: [UIGestureRecognizer]!
    
    var _prevTranslation: CGPoint?
    func panned(sender: UIPanGestureRecognizer) {
        if !templateEditMode { return }
        let translation = sender.translationInView(superview!)
        if let prev = _prevTranslation {
            frame = frame + (translation - prev)
        }
        _prevTranslation = translation
        if sender.state == .Ended { _prevTranslation = nil }
        _updateDragging()
    }
    
    func tapped(sender: UITapGestureRecognizer) {
        tapped()
    }
    
    var _prevArea: CGRect?
    func pinched(sender: UIPinchGestureRecognizer) {
        if !templateEditMode { return }
        if sender.state == .Changed && sender.numberOfTouches() == 2 {
            let area = sender.boundingRectOfTouchesInView(superview!)
            if let prev = _prevArea {
                let dp = area.origin - prev.origin
                let dSize = area.size - prev.size
                frame = (frame + dp) + dSize
            }
            _prevArea = area
        }
        if sender.state == .Ended {
            _prevArea = nil
            if frame.size.width <= 0 || frame.size.height <= 0 {
                removeFromSuperview()
            }
        }
        _updateDragging()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panRec && otherGestureRecognizer == pinchRec || gestureRecognizer == pinchRec && otherGestureRecognizer == panRec {
            return true
        }
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if panRec.numberOfTouches() > 0 {
            return true
        }
        return CGRectContainsPoint(bounds, touch.locationInView(self))
    }
    
    func _updateDragging() {
        self.dragging = self.pinchRec.numberOfTouches() + self.panRec.numberOfTouches() + self.tapRec.numberOfTouches() > 0
    }
    
    func _windowTouchedEnded(notif: NSNotification) {
        if dragging { dragging = false }
        delay(0.01) { 
            if self.dragging { self.dragging = false }
        }
    }
    
    var dragging = false {
        willSet(newVal) {
            if newVal {
                card?.showProposalRectForView(self)
            } else if !newVal && dragging {
                // we're done dragging:
                card?.showProposalRectForView(nil)
                frame = card!.proposedFrameForView(self)
                
                if !CGRectIntersectsRect(card!.bounds, frame) || CGRectEqualToRect(frame, CGRectZero) {
                    removeFromSuperview()
                }
            }
        }
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        _updateDragging()
        if dragging {
            return true
        }
        return super.pointInside(point, withEvent: event)
    }
    
    // MARK: Json
    class func FromJson(j: [String: AnyObject]) -> CardItemView? {
        let type = j["type"] as? String ?? ""
        var item: CardItemView?
        switch type {
        case "text":
            item = TextCardItemView()
        case "image":
            item = ImageCardItemView()
        case "profile":
            item = ProfileCardItemView()
        case "counter":
            item = CounterCardItemView()
        case "likes":
            item = LikeCounterCardItemView()
        case "button":
            item = ButtonCardItemView()
        case "messageMe":
            item = MessageMeCardItemView()
        case "countdown":
            item = CountdownCardItemView()
        case "map":
            item = MapCardItemView()
        case "sound":
            item = SoundCardItemView()
        default: ()
        }
        item?.importJson(j)
        return item
    }
    func importJson(json: [String: AnyObject]) {
        if let frameStr = json["frame"] as? String {
            frame = CGRectFromString(frameStr)
        }
    }
    func toJson() -> [String: AnyObject] {
        var j = [String: AnyObject]()
        j["frame"] = NSStringFromCGRect(frame)
        return j
    }
    func detachFromTemplate() {
        
    }
    
    func prepareToPresent() {
        editMode = false
        templateEditMode = false
    }
    
    func prepareToEditWithExistingTemplate() {
        editMode = true
        templateEditMode = false
    }
    
    func prepareToEditTemplate() {
        editMode = true
        templateEditMode = true
    }
    
    func onInsert() {
        
    }
}

extension UIGestureRecognizer {
    func boundingRectOfTouchesInView(view: UIView) -> CGRect! {
        let positions = (0..<numberOfTouches()).map({ locationOfTouch($0, inView: view) })
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
