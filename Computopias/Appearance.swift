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
    
    static func gradientForHashtag(hashtag: String) -> UIImage {
        return gradients[abs(hashtag.hash) % gradients.count]
    }
    
    static let transparentWhite = UIColor(white: 1, alpha: 0.3)
    
    static let tint = UIColor(red: 0.981, green: 0, blue: 0.331, alpha: 1)
    
    static func setup() {
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).defaultTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
}
