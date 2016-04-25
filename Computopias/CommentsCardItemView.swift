//
//  CommentsCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/26/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase
import AsyncDisplayKit

class CommentsCardItemView: CardItemView {
    // MARK: Data
    var chatID: String? {
        didSet {
            if let h = _fbHandle {
                Data.firebase.removeObserverWithHandle(h)
            }
            if let id = chatID {
                let firebase = Data.firebase.childByAppendingPath("chats").childByAppendingPath(id).childByAppendingPath("count")
                _fbHandle = firebase.observeEventType(.Value, withBlock: { [weak self] (let snapshot) in
                    self?._count = snapshot?.value as? Int ?? 0
                })
            }
        }
    }
    var _fbHandle: UInt?
    var _count: Int? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func onInsert() {
        super.onInsert()
        if chatID == nil {
            chatID = NSUUID().UUIDString
        }
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "comments"
        j["chatID"] = chatID
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        chatID = json["chatID"] as? String ?? chatID
    }
    
    override func detachFromTemplate() {
        super.detachFromTemplate()
        chatID = NSUUID().UUIDString
    }
    
    override func setup() {
        super.setup()
        opaque = false
        needsDisplayOnBoundsChange = true
    }
    
    // MARK: Lifecycle
    deinit {
        chatID = nil
    }
    // MARK: UI
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        var text = "Comments"
        if let c = _count {
            if c == 1 {
                text = "1 comment"
            } else {
                text = "\(c) comments"
            }
        }
        text = "💬 " + text
        var attrs = [String: AnyObject]()
        attrs[NSFontAttributeName] = TextCardItemView.font.fontWithSize(12)
        attrs[NSParagraphStyleAttributeName] = NSAttributedString.paragraphStyleWithTextAlignment(.Center)
        return NSAttributedString(string: text, attributes: attrs)
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let string = withParameters as! NSAttributedString
        string.drawVerticallyCenteredInRect(textInsetBoundsForBounds(bounds))
    }
    
    override func tapped() -> Bool {
        let chat = CommentsViewController()
        if let cardID = card?.cardFirebase?.key, let hashtag = card?.hashtag, let theChatID = chatID {
            chat.onComment = {
                Data.notifyComment(theChatID, cardID: cardID, hashtag: hashtag)
            }
        }
        chat.chat = Data.firebase.childByAppendingPath("chats").childByAppendingPath(chatID!)
        let nav = UINavigationController(rootViewController: chat)
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(nav, animated: true, completion: nil)
        return true
    }
    
    override var defaultSize: GridSize{
        get {
            return GridSize(width: 3, height: 1)
        }
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
}
