//
//  UIImage+Emoji.swift
//  ImageCascadeEffects
//
//  Created by Nate Parrott on 4/13/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIImage {
    class func fromEmoji(emoji: String, approxSize: CGFloat) -> UIImage {
        let font = UIFont.systemFontOfSize(approxSize)
        let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        para.alignment = .Center
        let str = NSAttributedString(string: emoji, attributes: [NSFontAttributeName: font, NSParagraphStyleAttributeName: para])
        let size = CGSizeMake(approxSize, round(approxSize * 1.1))
        UIGraphicsBeginImageContext(size)
        str.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
