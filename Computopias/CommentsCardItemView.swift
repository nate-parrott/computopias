//
//  CommentsCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/26/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

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
                    self?._count = snapshot?.value as? Int
                })
            }
        }
    }
    var _fbHandle: UInt?
    var _count: Int? {
        didSet {
            _updateUI()
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
    
    // MARK: Lifecycle
    override func setup() {
        super.setup()
        addSubview(label)
    }
    deinit {
        chatID = nil
    }
    // MARK: UI
    let label = UILabel()
    func _updateUI() {
        var text = "Comments"
        if let c = _count {
            if c == 1 {
                text = "1 comment"
            } else {
                text = "\(c) comments"
            }
        }
        label.text = "💬 " + text
    }
    
    override func tapped() {
        // TODO: open chat thread
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = textInsetBounds
        label.font = TextCardItemView.font.fontWithSize(generousFontSize)
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
}
