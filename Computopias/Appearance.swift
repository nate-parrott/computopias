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
    
    static func colorForHashtag(hashtag: String) -> UIColor {
        return colors[abs(hashtag.hash) % colors.count]
    }
}
