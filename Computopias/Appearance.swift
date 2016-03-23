//
//  Appearance.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

struct Appearance {
    static let colors = "#EB7DCA #E4E4E4 #679FFF #67FFAA #F0FF67 #FF6767 #EDD061 #905FFF".componentsSeparatedByString(" ").map({ UIColor(hex: $0)! })
    
    static func colorForHashtag(hashtag: String) -> UIColor {
        return colors[hashtag.hash % (colors.count-1)]
    }
}