//
//  LabelNode.swift
//  Computopias
//
//  Created by Nate Parrott on 4/12/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class LabelNode: ASDisplayNode {
    override init() {
        super.init()
        opaque = false
        needsDisplayOnBoundsChange = true
    }
    
    override func didLoad() {
        super.didLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LabelNode._tapped)))
    }
    
    func _tapped() {
        if let t = onTap { t() }
    }
    
    // MARK: API
    var attributedString: NSAttributedString? {
        didSet {
            if oldValue != attributedString {
                setNeedsDisplay()
            }
        }
    }
    
    var percentWidth: CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var onTap: (() -> ())?
    
    class DrawParams: NSObject {
        var str: NSAttributedString?
        var bounds: CGRect!
    }
    
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        let d = DrawParams()
        d.str = attributedString
        d.bounds = CGRectInset(bounds, bounds.size.width * (1 - percentWidth) / 2, 0)
        return d
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        if let d = withParameters as? DrawParams {
            d.str?.drawVerticallyCenteredInRect(d.bounds)
        }
    }
}
