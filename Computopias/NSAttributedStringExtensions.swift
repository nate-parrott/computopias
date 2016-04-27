//
//  NSAttributedStringExtensions.swift
//  Computopias
//
//  Created by Nate Parrott on 3/30/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension NSAttributedString {
    class func defaultFont() -> UIFont {
        return defaultFontAtSize(16)
    }
    
    class func defaultFontAtSize(size: CGFloat) -> UIFont {
        return UIFont.systemFontOfSize(size)
    }
    
    class func defaultBoldFontAtSize(size: CGFloat) -> UIFont {
        return UIFont.boldSystemFontOfSize(size)
    }
    
    class func defaultText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: defaultFont()])
    }
    
    class func defaultUnderlinedText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: defaultFont(), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
    }
    
    class func smallText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: defaultFontAtSize(13)])
    }
    
    class func smallUnderlinedText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: defaultFontAtSize(13), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
    }
    
    class func smallBoldText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: defaultBoldFontAtSize(13)])
    }
    
    class func largeText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(22, weight: UIFontWeightLight)])
    }
    
    class func paragraphStyleWithTextAlignment(align: NSTextAlignment) -> NSParagraphStyle {
        let m = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        m.alignment = align
        return m
    }
    
    func drawVerticallyCenteredInRect(rect: CGRect) {
        if length == 0 { return }
        let size = boundingRectWithSize(rect.size, options: [.UsesLineFragmentOrigin], context: nil)
        var d = CGRectMake(0, 0, rect.size.width, size.height)
        d.center = rect.center
        drawInRect(CGRectIntegral(d))
    }
    
    func drawFillingRect(rect: CGRect) {
        let text = resizeToFitInside(rect.size)
        let size = text.boundingRectWithSize(rect.size, options: [.UsesLineFragmentOrigin], context: nil)
        var d = CGRectMake(0, 0, rect.size.width, size.height)
        d.center = rect.center
        text.drawInRect(CGRectIntegral(d))
    }
}

func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let m = NSMutableAttributedString(attributedString: lhs)
    m.appendAttributedString(rhs)
    return m
}
