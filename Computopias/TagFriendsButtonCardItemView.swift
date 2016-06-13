//
//  TagFriendsButtonCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 6/12/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import  AsyncDisplayKit

class TagFriendsButtonCardItemView: CardItemView {
    let icon = ASImageNode()
    override func setup() {
        super.setup()
        addSubnode(icon)
        icon.image = UIImage(named: "LargeTagIcon")?.imageWithRenderingMode(.AlwaysTemplate)
        icon.tintColor = UIColor(white: 0, alpha: 0.5)
        icon.contentMode = .Center
        icon.layerBacked = true
    }
    override func layout() {
        super.layout()
        icon.frame = CGRect(center: bounds.center, size: bounds.size * 0.5).integral
    }
    override var needsNoView: Bool {
        get {
            return true
        }
    }
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "tagFriendsButton"
        return j
    }
    override func tapped() -> Bool {
        if let c = card {
            c.ensureTaggingView().tagMode = true
            return true
        } else {
            return false
        }
    }
    override var defaultSize: GridSize {
        get {
            return GridSize(width: 1, height: 1)
        }
    }
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return GridSize(width: min(size.width, size.height), height: min(size.width, size.height))
    }
}
