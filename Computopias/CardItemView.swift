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
    }
    
    var cardPath: Firebase?
    
    func setup() {
        
    }
    
    func tapped() {
        
    }
    
    func acceptsTouches() -> Bool {
        return false
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
    var templateEditMode = true
    
    var card: CardView? {
        get {
            return superview as? CardView
        }
    }
    
    // MARK: VCs
    
    func presentViewController(vc: UIViewController) {
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(vc, animated: true, completion: nil)
    }
    
    // MARK: Layout
    var margin: CGFloat {
        get {
            return 2
        }
    }
    
    var insetBounds: CGRect {
        get {
            return CGRectInset(bounds, margin, margin)
        }
    }
    
    var textMargin: CGFloat {
        get {
            return margin + 3
        }
    }
    
    var textInsetBounds: CGRect {
        get {
            return CGRectInset(bounds, textMargin, textMargin)
        }
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
        case "drawing":
            item = DrawingCardItemView()
        case "comments":
            item = CommentsCardItemView()
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
