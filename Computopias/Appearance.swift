//
//  Appearance.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

struct Appearance {
    static let colors = "#905FFF #EB7DCA #FFD122 #E65050 #EAE865 #5AE095 #679FFF #D9D9D9 #FF5F85".componentsSeparatedByString(" ").map({ UIColor(hex: $0)! })
    
    static let gradients = (1..<11).map({ UIImage(named: "g\($0)")! })
    
    /*static func colorForHashtag(hashtag: String) -> UIColor {
        return colors[abs(hashtag.hash) % colors.count]
    }*/
    
    static func gradientForHashtag(hashtag: String, cardID: String?) -> UIImage {
        let key = hashtag + "/" + (cardID ?? "")
        return gradients[abs(key.hash) % gradients.count]
    }
    static func gradientForString(key: String) -> UIImage {
        return gradients[abs(key.hash) % gradients.count]
    }
    
    static let transparentWhite = UIColor(white: 1, alpha: 0.3)
    
    static let tint = UIColor(hex: "#FF74A3")!
    
    static func setup() {
        // UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).defaultTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
    
    static let OverlayViewToolbarBackground = UIColor(white: 0.1, alpha: 0.6)
    static let OverlayViewToolbarFont = UIFont.boldSystemFontOfSize(16)
    static let OverlayViewToolbarHeight: CGFloat = 44
}
