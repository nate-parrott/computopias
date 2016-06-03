//
//  DrawingView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/24/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class DrawingView: ASDisplayNode {
    override init() {
        super.init()
        
        addSubnode(snapshotContainer)
        
        addSubnode(toolbar)
        toolbar.backgroundColor = Appearance.OverlayViewToolbarBackground
        toolbar.tintColor = UIColor.whiteColor()
        
        let font = Appearance.OverlayViewToolbarFont
        let color = UIColor.whiteColor()
        
        toolbar.addSubnode(doneButton)
        // doneButton.setImage(UIImage(named: "Checkmark"), forState: .Normal)
        doneButton.setTitle("Done", withFont: font, withColor: color, forState: .Normal)
        doneButton.addTarget(self, action: #selector(DrawingView.done(_:)), forControlEvents: .TouchUpInside)
        doneButton.tintColor = UIColor.whiteColor()
        
        toolbar.addSubnode(clearButton)
        clearButton.setTitle("Clear", withFont: font, withColor: color, forState: .Normal)
        clearButton.addTarget(self, action: #selector(DrawingView.clear), forControlEvents: .TouchUpInside)
        
        toolbar.addSubnode(undoButton)
        undoButton.setTitle("Undo", withFont: font, withColor: color, forState: .Normal)
        undoButton.addTarget(self, action: #selector(DrawingView.undo), forControlEvents: .TouchUpInside)
        
        strokeLayer.fillColor = nil
        strokeLayer.strokeColor = UIColor.blackColor().CGColor
        strokeLayer.lineWidth = 2
        
        toolbar.hidden = true
        userInteractionEnabled = false
    }
    
    override func didLoad() {
        super.didLoad()
        snapshotContainer.layer.addSublayer(strokeLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let snapshotContainer = ASDisplayNode()
    let strokeLayer = CAShapeLayer()
    let toolbar = ASDisplayNode()
    let doneButton = ASButtonNode()
    let undoButton = ASButtonNode()
    let clearButton = ASButtonNode()
    
    override func layout() {
        super.layout()
        toolbar.frame = CGRectMake(0, bounds.size.height-Appearance.OverlayViewToolbarHeight, bounds.size.width, Appearance.OverlayViewToolbarHeight)
        let doneSize = doneButton.measure(toolbar.bounds.size)
        let padding = (toolbar.bounds.height - doneSize.height)/2
        doneButton.frame = CGRectMake(toolbar.bounds.size.width-doneSize.width-padding*2, padding, doneSize.width, doneSize.height)
        doneButton.hitTestSlop = UIEdgeInsetsMake(-padding, -padding, -padding, -padding)
        snapshotContainer.frame = bounds
        strokeLayer.frame = snapshotContainer.bounds
        
        var x: CGFloat = 0
        for btn in [clearButton, undoButton] {
            let buttonSize = btn.measure(toolbar.frame.size)
            let slop = (toolbar.bounds.height - buttonSize.height)/2
            btn.frame = CGRectMake(x + slop, (toolbar.bounds.height - buttonSize.height)/2, buttonSize.width, buttonSize.height)
            btn.hitTestSlop = UIEdgeInsetsMake(-slop, -slop, -slop, -slop)
            x = btn.frame.right+slop
        }
    }
    
    func getImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        snapshotContainer.view.drawViewHierarchyInRect(bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func done(sender: UIButton) {
        if let d = onDone {
            d(self)
        }
    }
    
    var _prevPaths = [UIBezierPath]() {
        didSet {
            undoButton.enabled = _prevPaths.count > 0
            if _prevPaths.count > 20 {
                _prevPaths.removeAtIndex(0)
            }
        }
    }
    var _path = UIBezierPath() {
        didSet(oldVal) {
            mainThread { 
                self.strokeLayer.path = self._path.CGPath
            }
        }
    }
    
    func undo() {
        if let p = _prevPaths.last {
            _path = p
            _prevPaths.removeLast()
        }
    }
    func clear() {
        _prevPaths.append(_path)
        _path = UIBezierPath()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        _prevPaths.append(_path.copy() as! UIBezierPath)
        _path.moveToPoint(touches.first!.locationInView(view))
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        _path.addLineToPoint(touches.first!.locationInView(view))
        strokeLayer.path = _path.CGPath
        item?.path = _path
    }
    
    var drawingModeActive = false {
        didSet {
            toolbar.hidden = !drawingModeActive
            userInteractionEnabled = drawingModeActive
        }
    }
    var item: DrawingCardItemView? {
        didSet {
            _path = item?.path ?? UIBezierPath()
        }
    }
    
    var onDone: (DrawingView -> ())?
}

extension UIBezierPath {
    var base64String: String {
        get {
            let data = NSKeyedArchiver.archivedDataWithRootObject(self)
            return data.base64EncodedStringWithOptions([])
        }
    }
    class func fromBase64String(str: String) -> UIBezierPath? {
        if let data = NSData(base64EncodedString: str, options: []) {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? UIBezierPath
        }
        return nil
    }
}

