//
//  ASTextNodeAdditions.swift
//  Computopias
//
//  Created by Nate Parrott on 4/9/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import AsyncDisplayKit
import UIKit

class ASLabelNode: ASDisplayNode {
    struct Content {
        var font: UIFont
        var color: UIColor
        var alignment: NSTextAlignment
        var text: String
        static let Default = Content(font: UIFont.systemFontOfSize(UIFont.systemFontSize()), color: UIColor.blackColor(), alignment: .Center, text: "")
    }
    
    override init() {
        super.init()
        opaque = false
    }
    
    var padding: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    class DrawParams: NSObject {
        var str: NSAttributedString?
        var padding: CGFloat = 0
    }
    
    var attributedString: NSAttributedString? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var content: Content = Content.Default {
        didSet {
            if !(content == oldValue) {
                let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                para.alignment = content.alignment
                let attrs = [NSFontAttributeName: content.font, NSForegroundColorAttributeName: content.color, NSParagraphStyleAttributeName: para]
                let str = NSAttributedString(string: content.text, attributes: attrs)
                attributedString = str
            }
        }
    }
    
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        let p = DrawParams()
        p.str = attributedString
        p.padding = padding
        return p
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        if let p = withParameters as? DrawParams, let s = p.str {
            s.drawVerticallyCenteredInRect(CGRectInset(bounds, p.padding, p.padding))
        }
    }
}

func ==(left: ASLabelNode.Content, right: ASLabelNode.Content) -> Bool {
    return left.font == right.font && left.color == right.color && left.alignment.rawValue == right.alignment.rawValue && left.text == right.text
}
