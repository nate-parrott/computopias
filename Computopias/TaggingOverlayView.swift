//
//  TaggingOverlayView.swift
//  Computopias
//
//  Created by Nate Parrott on 4/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Firebase

class TaggingOverlayView: ASDisplayNode {
    override init() {
        super.init()
        userInteractionEnabled = false
        opaque = false
        needsDisplayOnBoundsChange = true
    }
    override func didLoad() {
        super.didLoad()
        let tapRec = UITapGestureRecognizer(target: self, action: #selector(TaggingOverlayView.tapped))
        view.addGestureRecognizer(tapRec)
    }
    var tagMode = false {
        didSet {
            userInteractionEnabled = tagMode
            setNeedsDisplay()
        }
    }
    func tapped(tapRec: UITapGestureRecognizer) {
        let tapPos = tapRec.locationInView(view)
        if tapPos.y >= bounds.size.height - Appearance.OverlayViewToolbarHeight {
            tagMode = false
        } else {
            let friendList = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FriendList") as! FriendListViewController
            friendList.onFriendSelect = {
                (id: String) in
                Data.userJsonForUser(id, callback: { (let userInfoOpt) in
                    if let userInfo = userInfoOpt {
                        let dict: [String: AnyObject] = ["x": tapPos.x, "y": tapPos.y, "user": userInfo]
                        self.tags.append(dict)
                        self.cardFirebase?.childByAppendingPath("tags").childByAutoId().setValue(dict)
                        if let cardFb = self.cardFirebase {
                            // find the hashtag for this card:
                            cardFb.childByAppendingPath("hashtag").get({ (let obj) in
                                if let hashtag = obj as? String {
                                    Data.notifyTag(id, cardID: cardFb.key, hashtag: hashtag)
                                }
                            })
                        }
                    }
                })
            }
            NPSoftModalPresentationController.presentViewController(UINavigationController(rootViewController: friendList))
        }
    }
    
    // MARK: API
    var cardFirebase: Firebase?
    var tags = [[String: AnyObject]]() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Drawing
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        let info = DrawInfo()
        info.tagModeActive = tagMode
        info.tags = tags
        return info
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let tagFont = TextCardItemView.boldFont.fontWithSize(11)
        let padding: CGSize = CGSizeMake(5, 2)
        let calloutHeight: CGFloat = 3
        let calloutWidth = calloutHeight * sqrt(2)
        let cornerRadius: CGFloat = 3
        let info = withParameters as! DrawInfo
        
        let tagAttrs: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor(white: 0, alpha: 0.6),
            NSFontAttributeName: tagFont
        ]
        
        for tag in info.tags ?? [] {
            if let x = tag["x"] as? CGFloat, let y = tag["y"] as? CGFloat, let user = tag["user"] as? [String: AnyObject], let name = user["name"] as? String {
                
                let str = NSAttributedString(string: name.uppercaseString, attributes: tagAttrs)
                let textSize = str.size()
                let boxSize = CGSizeMake(textSize.width + padding.width * 2, textSize.height + padding.height * 2)
                let box = CGRectMake(x, y - boxSize.height - calloutHeight, boxSize.width, boxSize.height)
                let boxPath = UIBezierPath(roundedRect: box, cornerRadius: cornerRadius)
                let callout = UIBezierPath()
                callout.moveToPoint(CGPointMake(x, y))
                callout.addLineToPoint(CGPointMake(x, y - calloutHeight - cornerRadius))
                callout.addLineToPoint(CGPointMake(x + calloutWidth, y - calloutHeight - cornerRadius))
                callout.addLineToPoint(CGPointMake(x + calloutWidth, y - calloutHeight))
                callout.closePath()
                boxPath.appendPath(callout)
                UIColor(white: 1, alpha: 0.5).setFill()
                boxPath.fill()
                str.drawAtPoint(CGPointMake(box.origin.x + padding.width, box.origin.y + padding.height))
            }
        }
        
        if info.tagModeActive {
            let toolbarFrame = CGRectMake(0, bounds.size.height - Appearance.OverlayViewToolbarHeight, bounds.size.width, Appearance.OverlayViewToolbarHeight)
            Appearance.OverlayViewToolbarBackground.setFill()
            UIBezierPath(rect: toolbarFrame).fill()
            
            let toolbarAttrs: [String: AnyObject] = [
                NSFontAttributeName: Appearance.OverlayViewToolbarFont,
                NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.66),
                NSParagraphStyleAttributeName: NSAttributedString.paragraphStyleWithTextAlignment(.Center)
            ]
            let promptStr = NSAttributedString(string: "Tap to Tag Friends", attributes: toolbarAttrs)
            let promptSize = promptStr.size()
            promptStr.drawAtPoint(CGPointMake((bounds.size.width - promptSize.width)/2, toolbarFrame.origin.y + (bounds.size.height - promptSize.height)/2))
            
            let doneAttrs: [String: AnyObject] = [
                NSFontAttributeName: Appearance.OverlayViewToolbarFont,
                NSForegroundColorAttributeName: UIColor.whiteColor()
            ]
            let doneStr = NSAttributedString(string: "Done", attributes: doneAttrs)
            let doneSize = doneStr.size()
            let donePadding = (toolbarFrame.size.height - doneSize.height)/2
            doneStr.drawAtPoint(CGPointMake(toolbarFrame.size.width - donePadding*2 - doneSize.width, toolbarFrame.origin.y + donePadding))
        }
    }
    
    class DrawInfo: NSObject {
        var tags: [[String: AnyObject]]?
        var tagModeActive = false
    }
}
