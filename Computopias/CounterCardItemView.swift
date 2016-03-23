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
            _update()
        }
    }
    
    static let someEmoji = "🌟 🔥 👌 💸 🌀 📣 🍃 👍 😀 😈 👻 👀 🎅 💋 🌎 🎃 🌴 🐳 🍔 🍺 ☕️ ⚽️ 🎯 🚀 🎉 🎁 💯".componentsSeparatedByString(" ")
    class func randomEmoji() -> String {
        return CounterCardItemView.someEmoji[abs(random()) % CounterCardItemView.someEmoji.count]
    }
    
    override func setup() {
        super.setup()
        selectedByMe = false
        count = 0
        addSubview(label)
        label.font = TextCardItemView.font
        label.textAlignment = .Center
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
            if let dict = snapshot.value as? [String: AnyObject] {
                self?.selectedByMe = dict[Data.getUID()] != nil
                self?.count = dict.count
            } else {
                self?.selectedByMe = false
                self?.count = 0
            }
            })
    }
    
    var selectedByMe = false {
        didSet {
            label.alpha = selectedByMe ? 1 : 0.5
        }
    }
    var count: Int = 0 {
        didSet {
            _update()
        }
    }
    
    func _update() {
        label.text = " \(emoji) \(count)"
    }
    
    override func tapped() {
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
    }
    
    func willModifyCount(add: Int) {
        
    }
    
    let label = UILabel()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
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
}
