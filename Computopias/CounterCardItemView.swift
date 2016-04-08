//
//  CounterCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class CounterCardItemView: CardItemView {
    var counterID = NSUUID().UUIDString
    var emoji: String = CounterCardItemView.randomEmoji() {
        didSet {
            _updateText()
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
        addSubview(label)
        label.font = TextCardItemView.font
        label.layer.cornerRadius = CardView.rounding
        label.clipsToBounds = true
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
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
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
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
    
    var selectedByMe = false {
        didSet {
            _updateText()
        }
    }
    var count: Int = 0 {
        didSet {
            _updateText()
        }
    }
    
    func _updateText() {
        var attributes = [String: AnyObject]()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = TextCardItemView.font.fontWithSize(generousFontSize)
        if selectedByMe {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 8
            shadow.shadowOffset = CGSizeMake(0, 1)
            shadow.shadowColor = UIColor.whiteColor()
            attributes[NSShadowAttributeName] = shadow
        }
        let text = " \(emoji) \(count)"
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
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
    
    let label = UILabel()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = textInsetBounds
        _updateText()
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
                label.textAlignment = .Center
            case .Full:
                label.textAlignment = .Center
            case .Trailing:
                label.textAlignment = .Right
            case .Leading:
                label.textAlignment = .Left
            }
        }
    }
}
