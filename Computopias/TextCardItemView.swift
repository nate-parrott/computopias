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
        field.textContainer.lineFragmentPadding = 0
        field.dataDetectorTypes = .All
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
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.selectedRange = NSMakeRange(0, (textView.text as NSString).length)
    }
    
    func textViewDidChange(textView: UITextView) {
        delay(0) { 
            if self.staticLabel && textView.numberOfLines > 0 {
                // can we extend this horizontally?
                if let newFrame = self.card?.frameForHorizontalExpansionOfView(self) {
                    self.frame = newFrame
                }
            }
        }
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
        field.backgroundColor = staticLabel ? nil : Appearance.transparentWhite
    }
    
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(staticLabel ? 2 : -1, 1)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointZero
    }
    
    let field = UITextView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        field.frame = insetBounds
        var inset = UIEdgeInsetsMake(textMargin - margin, textMargin - margin, textMargin - margin, textMargin - margin)
        inset.top = (card!.gridCellSize.height - field.font!.pointSize)/2 - 4
        field.textContainerInset = inset
        field.layer.cornerRadius = CardView.rounding
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
    
    override var alignment: (x: CardItemView.Alignment, y: CardItemView.Alignment) {
        didSet {
            switch alignment.x {
            case .Middle:
                field.textAlignment = .Center
            case .Trailing:
                field.textAlignment = .Right
            default: field.textAlignment = .Left
            }
        }
    }
}

extension UITextView {
    var numberOfLines: Int {
        get {
            var i = 0
            layoutManager.enumerateLineFragmentsForGlyphRange(NSRange(location: 0, length: layoutManager.numberOfGlyphs)) { (_, _, _, _, _) in
                i += 1
            }
            return i
        }
    }
}
