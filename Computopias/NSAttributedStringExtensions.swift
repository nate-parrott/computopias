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
}

func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let m = NSMutableAttributedString(attributedString: lhs)
    m.appendAttributedString(rhs)
    return m
}
