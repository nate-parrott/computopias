//
//  LabelCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class TextCardItemView: CardItemView, UITextViewDelegate {
    override func setup() {
        super.setup()
        addSubview(field)
        field.text = "Tap to edit"
        field.delegate = self
        field.userInteractionEnabled = false
        field.backgroundColor = UIColor.clearColor()
        field.scrollEnabled = false
        self.staticLabel = false
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        field.userInteractionEnabled = false
    }
    
    override func tapped() {
        super.tapped()
        field.userInteractionEnabled = true
        field.becomeFirstResponder()
    }
    
    var staticLabel = false {
        didSet {
            field.layer.borderColor = UIColor(white: 0.5, alpha: staticLabel ? 0 : 0.5).CGColor
            field.alpha = staticLabel ? 0.5 : 1
            field.layer.borderWidth = 1
        }
    }
    var large = false
    
    override var defaultSize: GridSize {
        get {
            if large {
                return CGSizeMake(-1, 2)
            } else {
                return CGSizeMake(-1, 1)
            }
        }
    }
    
    let field = UITextView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        field.frame = bounds
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "text"
        j["text"] = field.text ?? ""
        return j
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        field.text = json["text"] as? String ?? ""
    }
}
