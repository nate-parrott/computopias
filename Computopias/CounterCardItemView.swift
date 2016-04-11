//
//  CounterCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase
import AsyncDisplayKit

class CounterCardItemView: CardItemView {
    var counterID = NSUUID().UUIDString {
        didSet {
            _updateDataObservers()
        }
    }
    var emoji: String = CounterCardItemView.randomEmoji() {
        didSet {
            setNeedsDisplay()
        }
    }
    static let someEmoji = "🌟 🔥 👌 💸 🌀 📣 🍃 👍 😀 😈 👻 👀 🎅 💋 👍 🌎 😉 🎃 🌴 🐳 🍔 🌶 🍺 ☕️ ⚽️ 🎯 🚀 🎉 🎁 💯".componentsSeparatedByString(" ")
    class func randomEmoji() -> String {
        return CounterCardItemView.someEmoji[abs(random()) % CounterCardItemView.someEmoji.count]
    }
    
    override func setup() {
        super.setup()
        selectedByMe = false
        count = 0
        opaque = false
        _updateDataObservers()
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    
    func _updateDataObservers() {
        _observer = pathToObserve().observeEventType(FEventType.Value, withBlock: { [weak self] (let snapshot: FDataSnapshot!) -> Void in
            if let dict = snapshot.value as? [String: AnyObject], let uid = Data.getUID() {
                self?.selectedByMe = dict[uid] != nil
                self?.count = dict.count
            } else {
                self?.selectedByMe = false
                self?.count = 0
            }
            })
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        counterID = json["counterID"] as? String ?? ""
        emoji = json["emoji"] as? String ?? emoji
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["counterID"] = counterID
        j["emoji"] = emoji
        j["type"] = "counter"
        return j
    }
    
    var selectedByMe = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var count: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        var attributes = [String: AnyObject]()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = TextCardItemView.font.fontWithSize(generousFontSize)
        let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        para.alignment = textAlignment
        attributes[NSParagraphStyleAttributeName] = para
        if selectedByMe {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 8
            shadow.shadowOffset = CGSizeMake(0, 1)
            shadow.shadowColor = UIColor.whiteColor()
            attributes[NSShadowAttributeName] = shadow
        }
        let text = " \(emoji) \(count)"
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    // + (void)drawRect:(CGRect)bounds withParameters:(nullable id <NSObject>)parameters
    // isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock
    // isRasterizing:(BOOL)isRasterizing;
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let string = withParameters as! NSAttributedString
        string.drawVerticallyCenteredInRect(CardItemView.textInsetBoundsForBounds(bounds))
    }
    
    override func tapped() -> Bool {
        super.tapped()
        if !editMode {
            let path = pathToObserve().childByAppendingPath(Data.getUID())
            if selectedByMe {
                willModifyCount(-1)
                path.removeValue()
            } else {
                willModifyCount(1)
                path.setValue(NSDate().timeIntervalSince1970)
            }
        }
        if templateEditMode {
            rotateEmoji()
        }
        return true
    }
    
    func rotateEmoji() {
        // emoji = CounterCardItemView.randomEmoji()
        if templateEditMode {
            let editor = UIAlertController(title: "Choose caption for voter", message: "Choose a title and a link", preferredStyle: .Alert)
            editor.addTextFieldWithConfigurationHandler({ (let field) in
                field.placeholder = "An emoji or a word"
                field.text = self.emoji
            })
            editor.addAction(UIAlertAction(title: "Done", style: .Default, handler: { (_) in
                self.emoji = editor.textFields![0].text ?? "🐳"
            }))
            presentViewController(editor)
        }
    }
    
    func willModifyCount(add: Int) {
        
    }
    
    func pathToObserve() -> Firebase {
        return Data.firebase.childByAppendingPath("counters").childByAppendingPath(counterID)
    }
    
    var _observer: UInt? {
        willSet(newVal) {
            if let o = _observer {
                Data.firebase.removeObserverWithHandle(o)
            }
        }
    }
    deinit {
        _observer = nil
    }
    
    override func detachFromTemplate() {
        super.detachFromTemplate()
        counterID = NSUUID().UUIDString
    }
    
    override var alignment: (x: CardItemView.Alignment, y: CardItemView.Alignment) {
        didSet {
            switch alignment.x {
            case .Middle:
                textAlignment = .Center
            case .Full:
                textAlignment = .Center
            case .Trailing:
                textAlignment = .Right
            case .Leading:
                textAlignment = .Left
            }
        }
    }
    
    var textAlignment = NSTextAlignment.Center {
        didSet {
            setNeedsDisplay()
        }
    }
}
