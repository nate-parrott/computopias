//
//  UIButton+Block.swift
//  Elastic
//
//  Created by Nate Parrott on 4/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CUButton: UIButton {
    convenience init(title: String, action: (() -> ())?) {
        self.init(frame: CGRectZero)
        setTitle(title, forState: .Normal)
        self.action = action
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if !_setup {
            _setup = true
            addTarget(self, action: #selector(CUButton._tapped), forControlEvents: .TouchUpInside)
            layer.cornerRadius = 2
            layer.borderWidth = 1.5
            titleLabel?.font = UIFont.boldSystemFontOfSize(15)
            tintColorDidChange()
        }
    }
    override func tintColorDidChange() {
        super.tintColorDidChange()
        layer.borderColor = tintColor.CGColor
        setTitleColor(tintColor, forState: .Normal)
    }
    var _setup = false
    var action: (() -> ())?
    func _tapped() {
        if let a = action { a() }
    }
    var padding = UIEdgeInsetsMake(5, 15, 5, 15) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    override func sizeThatFits(size: CGSize) -> CGSize {
        var s = super.sizeThatFits(size)
        s.width += padding.left + padding.right
        s.height += padding.top + padding.bottom
        return s
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.height/2
    }
}
