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
        field.font = TextCardItemView.font
        self.staticLabel = false
        field.tintColor = UIColor.whiteColor()
    }
    
    static let font = UIFont(name: "Futura-Medium", size: 15)!
    
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
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    
    override func tapped() {
        super.tapped()
        if templateEditMode || (editMode && !staticLabel) {
            field.userInteractionEnabled = true
            field.becomeFirstResponder()
        }
    }
    
    var staticLabel = false {
        didSet {
            _updateAppearance()
        }
    }
    
    override var editMode: Bool {
        didSet {
            _updateAppearance()
        }
    }
    
    func _updateAppearance() {
        field.layer.borderColor = UIColor(white: 1, alpha: staticLabel ? 0 : 0.5).CGColor
        field.alpha = staticLabel ? 0.5 : 1
        field.layer.borderWidth = editMode ? 1 : 0
        field.layer.cornerRadius = CardView.rounding
    }
    
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(-1, 1)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointZero
    }
    
    let field = UITextView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        field.frame = bounds
        var inset = field.textContainerInset
        inset.top = (card!.gridCellSize.height - field.font!.pointSize)/2 - 4
        field.textContainerInset = inset
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "text"
        j["text"] = field.text ?? ""
        j["staticLabel"] = staticLabel
        return j
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        field.text = json["text"] as? String ?? ""
        staticLabel = json["staticLabel"] as? Bool ?? false
    }
}
