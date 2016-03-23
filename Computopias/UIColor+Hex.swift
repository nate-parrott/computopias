//
//  UIColor+Hex.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/5/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init?(hex: String) {
        if hex.utf16.count == 7 {
            let red = UInt8(strtoul(hex[1...2], nil, 16))
            let green = UInt8(strtoul(hex[3...4], nil, 16))
            let blue = UInt8(strtoul(hex[5...6], nil, 16))
            self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1)
        } else {
            return nil
        }
    }
    
    var hex: String {
        get {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            if !getRed(&r, green: &g, blue: &b, alpha: nil) {
                var w: CGFloat = 0
                getWhite(&w, alpha: nil)
                r = w
                g = w
                b = w // TODO: make this technically correct (?)
            }
            return String(format: "#%2X%2X%2X", UInt8(r*255), UInt8(g*255), UInt8(b*255))
        }
    }
}
