//
//  StarRatingCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/31/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class StarRatingCardItemView: CardItemView {
    override func setup() {
        super.setup()
        opaque = false
        needsDisplayOnBoundsChange = true
        _updateDataObservers()
    }
    // MARK: Json
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        ratingID = json["ratingID"] as? String ?? ratingID
    }
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "starRating"
        j["ratingID"] = ratingID
        return j
    }
    // MARK: Data
    var ratingID = NSUUID().UUIDString {
        didSet {
            _updateDataObservers()
        }
    }
    override func detachFromTemplate() {
        super.detachFromTemplate()
        ratingID = NSUUID().UUIDString
    }
    func _updateDataObservers() {
        _ratingsSub = Data.firebase.childByAppendingPath("ratings").childByAppendingPath(ratingID).pusher.subscribe({ [weak self] (let ratings) in
            if let r = ratings as? [String: AnyObject] {
                self?._ratings = r
            } else {
                self?._ratings = [String: AnyObject]()
            }
        })
    }
    var _ratingsSub: Subscription?
    var _ratings: [String: AnyObject]? {
        didSet {
            setNeedsDisplay()
        }
    }
    // MARK: Layout
    override var defaultSize: GridSize {
        get {
            return GridSize(width: 4, height: 1)
        }
    }
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        var s = size
        s.width = max(s.width, 3)
        return s
    }
    // MARK: Interaction
    override func tapped(info: TapInfo) -> Bool {
        if !editMode {
            let score = Int(floor(info.position.x / bounds.size.width * 7)) - 1
            if score >= 0 && score <= 4 {
                rate(score)
                return true
            }
            self.card?.view.fireTouchParticleEffectAtPoint(convertPoint(info.position, toNode: supernode!), image: UIImage.fromEmoji("⭐️", approxSize: 60))
        }
        return false
    }
    
    func rate(score: Int?) {
        Data.firebase.childByAppendingPath("ratings").childByAppendingPath(ratingID).childByAppendingPath(Data.getUID()!).setValue(score)
    }
    
    // MARK: Rendering
    class RenderInfo: NSObject {
        var totalVotes: Int = 0
        var numVotes: Int = 0
        var selfVote: Int?
    }
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        if let ratings = _ratings {
            let info = RenderInfo()
            if let uid = Data.getUID() {
                info.selfVote = ratings[uid] as? Int
            }
            for item in ratings.values {
                if let score = item as? Int {
                    info.numVotes += 1
                    info.totalVotes += score
                }
            }
            return info
        } else {
            return nil
        }
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        if let info = withParameters as? RenderInfo {
            let cellSize = CGSizeMake(bounds.size.width / 7, bounds.size.height)
            let star = NSAttributedString(string: "⭐️", attributes: [NSParagraphStyleAttributeName: NSAttributedString.paragraphStyleWithTextAlignment(.Center)]).resizeToFitInside(cellSize * 0.7)
            let ctx = UIGraphicsGetCurrentContext()!
            var avgScore = -1
            if info.numVotes > 0 {
                avgScore = Int(round(Float(info.totalVotes) / Float(info.numVotes)))
            }
            for i in 0..<5 {
                let rect = CGRectMake(cellSize.width * CGFloat(1 + i), 0, cellSize.width, cellSize.height)
                let alpha: CGFloat = i <= avgScore ? 1.0 : 0.4
                CGContextSetAlpha(ctx, alpha)
                star.drawVerticallyCenteredInRect(rect)
            }
            CGContextSetAlpha(ctx, 1)
            
            var attrs = [String: AnyObject]()
            attrs[NSFontAttributeName] = UIFont.boldSystemFontOfSize(20)
            attrs[NSParagraphStyleAttributeName] = NSAttributedString.paragraphStyleWithTextAlignment(.Center)
            let text = NSAttributedString(string: "\(info.numVotes)", attributes: attrs)
            var rect = CGRectMake(0, 0, bounds.size.width/7, bounds.size.height)
            rect = CGRectInset(rect, rect.width * 0.15, rect.height * 0.15)
            text.drawFillingRect(rect)
            
            if let score = info.selfVote {
                let pointSize = min(cellSize.width, cellSize.height) * 0.09
                UIColor.whiteColor().setFill()
                for i in 0..<5 {
                    let center = CGPointMake(cellSize.width * (1.5 + CGFloat(i)), cellSize.height * 0.9)
                    let ellipseRect = CGRectMake(center.x - pointSize, center.y - pointSize, pointSize, pointSize)
                    if i <= score {
                        UIBezierPath(ovalInRect: ellipseRect).fill()
                    }
                }
            }
        }
    }
    
    override var needsNoView: Bool {
        get {
            return true
        }
    }
}
