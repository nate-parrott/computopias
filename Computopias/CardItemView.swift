//
//  CardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase
import AsyncDisplayKit

class CardItemView: ASDisplayNode, UIGestureRecognizerDelegate {
    override init() {
        super.init()
        layerBacked = needsNoView
        setup()
    }
    
    var needsNoView: Bool {
        get {
            return false
        }
    }
    
    var cardPath: Firebase?
    
    func setup() {
        acceptsTouches = false
    }
    
    struct TapInfo {
        var position: CGPoint
    }
    
    func tapped() -> Bool {
        return false
    }
    
    func tapped(info: TapInfo) -> Bool {
        return tapped()
    }
    
    var acceptsTouches = false {
        didSet {
            userInteractionEnabled = acceptsTouches
        }
    }
    
    var defaultSize: GridSize {
        return CGSizeMake(2, 1)
    }
    
    func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return defaultSize
    }
    
    var editMode = true
    var templateEditMode = true
    
    var card: CardView? {
        get {
            return supernode?.supernode as? CardView
        }
    }
    
    // MARK: VCs
    
    func presentViewController(vc: UIViewController) {
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(vc, animated: true, completion: nil)
    }
    
    // MARK: Layout
    class var margin: CGFloat {
        get {
            return 2
        }
    }
    
    var margin: CGFloat {
        get {
            return CounterCardItemView.margin
        }
    }
    
    var insetBounds: CGRect {
        get {
            return CGRectInset(bounds, margin, margin)
        }
    }
    
    class func insetBoundsForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, margin, margin)
    }
    
    var textMargin: CGFloat {
        get {
            return CardItemView.textMargin
        }
    }
    
    class var textMargin: CGFloat {
        get {
            return margin + 3
        }
    }
    
    var textInsetBounds: CGRect {
        get {
            return CGRectInset(bounds, textMargin, textMargin)
        }
    }
    
    class func textInsetBoundsForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, textMargin, textMargin)
    }
    
    var generousFontSize: CGFloat {
        if let gridSize = card?.gridCellSize, let proposedSize = card?.proposedFrameForView(self) {
            let minDim = min(proposedSize.width / gridSize.width, proposedSize.height / gridSize.height)
            return minDim * TextCardItemView.font.pointSize
        } else {
            return TextCardItemView.font.pointSize
        }
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
        case "drawing":
            item = DrawingCardItemView()
        case "comments":
            item = CommentsCardItemView()
        case "random":
            item = RandomContentCardItemView()
        case "starRating":
            item = StarRatingCardItemView()
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
    
    // MARK: Events
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
    
    func prepareToEditInPlace(canEditTemplate: Bool) {
        editMode = true
        templateEditMode = canEditTemplate
    }
    
    func prepareToEditTemplate() {
        editMode = true
        templateEditMode = true
    }
    
    func onInsert() {
        
    }
    // MARK: CardView alignment
    enum Alignment {
        case Leading
        case Middle
        case Trailing
        case Full
        static func fromValues(containerMin: CGFloat, itemMin: CGFloat, itemMax: CGFloat, containerMax: CGFloat) -> Alignment {
            let leading = itemMin <= containerMin
            let trailing = itemMax >= containerMax
            switch (leading, trailing) {
            case (true, true): return .Full
            case (true, false): return .Leading
            case (false, true): return .Trailing
            case (false, false): return .Middle
            }
        }
        var textAlignment: NSTextAlignment {
            switch self {
            case .Leading: return .Left
            case .Middle: return .Center
            case .Trailing: return .Right
            case .Full: return .Center
            }
        }
    }
    var alignment = (x: Alignment.Middle, y: Alignment.Middle)
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
