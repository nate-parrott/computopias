//
//  DrawingCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/24/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class DrawingCardItemView: CardItemView {
    let icon = ASImageNode()
    
    override func setup() {
        super.setup()
        addSubnode(icon)
        icon.image = UIImage(named: "Pencil")
        icon.tintColor = UIColor(white: 0, alpha: 0.5)
        icon.contentMode = .Center
        icon.hidden = !editMode
    }
    
    override var defaultSize: GridSize{
        get {
            return GridSize(width: 1, height: 1)
        }
    }
    
    override func layout() {
        super.layout()
        icon.frame = insetBounds
    }
    
    override var editMode: Bool {
        didSet {
            icon.hidden = !editMode
        }
    }
    
    var path: UIBezierPath?
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "drawing"
        if let p = path {
            j["path"] = p.base64String
        }
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let s = json["path"] as? String, let p = UIBezierPath.fromBase64String(s) {
            path = p
        }
    }
    override func tapped() -> Bool {
        if editMode {
            card?.startDrawing()
            return true
        }
        return false
    }
}
