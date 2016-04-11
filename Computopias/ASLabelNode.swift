//
//  ASTextNodeAdditions.swift
//  Computopias
//
//  Created by Nate Parrott on 4/9/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import AsyncDisplayKit
import UIKit

class ASLabelNode: ASTextNode {
    struct Content {
        var font: UIFont
        var color: UIColor
        var alignment: NSTextAlignment
        var text: String
        static let Default = Content(font: UIFont.systemFontOfSize(UIFont.systemFontSize()), color: UIColor.blackColor(), alignment: .Center, text: "")
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
}

func ==(left: ASLabelNode.Content, right: ASLabelNode.Content) -> Bool {
    return left.font == right.font && left.color == right.color && left.alignment.rawValue == right.alignment.rawValue && left.text == right.text
}
