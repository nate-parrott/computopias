//
//  CardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardItemView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        let panRec = UIPanGestureRecognizer(target: self, action: "panned:")
        let tapRec = UITapGestureRecognizer(target: self, action: "tapped:")
        let pinchRec = UIPinchGestureRecognizer(target: self, action: "pinched:")
        gestureRecs = [panRec, tapRec, pinchRec]
        for r in gestureRecs {
            addGestureRecognizer(r)
        }
    }
    
    func setup() {
        
    }
    
    func tapped() {
        
    }
    
    var defaultSize: GridSize {
        return CGSizeMake(2, 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var editMode = true
    var templateEditMode = true
    
    // MARK: Gesture recs
    var gestureRecs: [UIGestureRecognizer]!
    
    var _prevTranslation: CGPoint?
    func panned(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(superview!)
        if let prev = _prevTranslation {
            frame = frame + (translation - prev)
        }
        _prevTranslation = translation
        if sender.state == .Ended { _prevTranslation = nil }
    }
    
    func tapped(sender: UITapGestureRecognizer) {
        tapped()
    }
    
    var _prevArea: CGRect?
    func pinched(sender: UIPinchGestureRecognizer) {
        if sender.state == .Changed {
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
        }
    }
    
    // MARK: Json
    class func FromJson(j: [String: AnyObject]) -> CardItemView? {
        let type = j["type"] as? String ?? ""
        var item: CardItemView?
        switch type {
            case "text":
            item = TextCardItemView()
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
