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
    
    class func defaultText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: defaultFont()])
    }
    
    class func defaultUnderlinedText(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: defaultFont(), NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
    }
}

func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
    let m = NSMutableAttributedString(attributedString: lhs)
    m.appendAttributedString(rhs)
    return m
}
