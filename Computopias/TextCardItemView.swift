//
//  LabelCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class TextCardItemView: CardItemView, ASEditableTextNodeDelegate {
    override func setup() {
        super.setup()
        addSubnode(fieldNode)
        setText("Tap to edit...")
        fieldNode.delegate = self
        fieldNode.backgroundColor = UIColor.clearColor()
        fieldNode.scrollEnabled = false
        
        // field.textContainer.lineFragmentPadding = 0
        // field.dataDetectorTypes = .All
        self.staticLabel = false
        tintColor = UIColor.whiteColor()
        _updateAppearance()
    }
    
    func setTextAttributes(attrs: [String: AnyObject]) {
        if let mText = fieldNode.attributedText?.mutableCopy() as? NSMutableAttributedString {
            mText.addAttributes(attrs, range: NSMakeRange(0, mText.length))
            fieldNode.attributedText = mText
        }
        fieldNode.typingAttributes = attrs
    }
    
    static let font = UIFont(name: "AvenirNext-Medium", size: 15)!
    static let boldFont = UIFont(name: "AvenirNext-DemiBold", size: 15)!
    
    func setText(text: String) {
        fieldNode.attributedText = NSAttributedString(string: text, attributes: fieldNode.typingAttributes ?? [String: AnyObject]())
    }
    
    // MARK: Text delegate
    func editableTextNodeDidUpdateText(editableTextNode: ASEditableTextNode) {
        delay(0) {
            if !self.backgrounded && self.fieldNode.textView.numberOfLines > 1 {
                // can we extend this horizontally?
                if let newFrame = self.card?.frameForHorizontalExpansionOfView(self) {
                    self.frame = newFrame
                }
            }
        }
    }
    func editableTextNodeDidBeginEditing(editableTextNode: ASEditableTextNode) {
        editableTextNode.textView.selectedRange = NSMakeRange(0, editableTextNode.attributedText?.length ?? 0)
    }
    func editableTextNodeDidFinishEditing(editableTextNode: ASEditableTextNode) {
        acceptsTouches = false
    }
    func editableTextNode(editableTextNode: ASEditableTextNode, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            editableTextNode.textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    
    override func tapped() -> Bool {
        super.tapped()
        if templateEditMode || (editMode && !staticLabel) {
            acceptsTouches = true
            fieldNode.textView.becomeFirstResponder()
            return true
        }
        return false
    }
    
    var staticLabel = false {
        didSet {
            _updateAppearance()
        }
    }
    
    var backgrounded = false {
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
        let font = backgrounded ? TextCardItemView.font : TextCardItemView.boldFont
        let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        para.alignment = _textAlignment
        setTextAttributes([NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.blackColor(), NSParagraphStyleAttributeName: para])
        fieldNode.backgroundColor = backgrounded ? Appearance.transparentWhite : nil
    }
    
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(backgrounded ? -1 : 2, 1)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointZero
    }
    
    let fieldNode = ASEditableTextNode()
    
    override func layout() {
        super.layout()
        fieldNode.frame = insetBounds
        var inset = UIEdgeInsetsMake(textMargin - margin, textMargin - margin, textMargin - margin, textMargin - margin)
        inset.top = (CardView.gridCellSize.height - TextCardItemView.font.pointSize)/2 - 4
        fieldNode.textContainerInset = inset
        fieldNode.cornerRadius = CardView.rounding
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "text"
        j["text"] = fieldNode.attributedText?.string ?? ""
        j["staticLabel"] = staticLabel
        j["backgrounded"] = backgrounded
        return j
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        setText(json["text"] as? String ?? "")
        staticLabel = json["staticLabel"] as? Bool ?? false
        backgrounded = json["backgrounded"] as? Bool ?? !staticLabel
    }
    
    override var alignment: (x: CardItemView.Alignment, y: CardItemView.Alignment) {
        didSet {
            switch alignment.x {
            case .Middle:
                _textAlignment = .Center
            case .Trailing:
                _textAlignment = .Right
            default: _textAlignment = .Left
            }
        }
    }
    
    var _textAlignment = NSTextAlignment.Center {
        didSet {
            if _textAlignment.rawValue != oldValue.rawValue {
                _updateAppearance()
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
