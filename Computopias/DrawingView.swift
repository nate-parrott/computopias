//
//  DrawingView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/24/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class DrawingView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(snapshotContainer)
        snapshotContainer.addSubview(imageView)
        snapshotContainer.layer.addSublayer(strokeLayer)
        addSubview(toolbar)
        imageView.contentMode = .ScaleAspectFit
        toolbar.backgroundColor = UIColor(white: 0.1, alpha: 0.6)
        toolbar.tintColor = UIColor.whiteColor()
        
        toolbar.addSubview(doneButton)
        doneButton.setImage(UIImage(named: "Checkmark"), forState: .Normal)
        doneButton.addTarget(self, action: #selector(DrawingView.done(_:)), forControlEvents: .TouchUpInside)
        
        toolbar.addSubview(clearButton)
        clearButton.setTitle("Clear", forState: .Normal)
        clearButton.addTarget(self, action: #selector(DrawingView.clear), forControlEvents: .TouchUpInside)
        
        toolbar.addSubview(undoButton)
        undoButton.setTitle("Undo", forState: .Normal)
        undoButton.addTarget(self, action: #selector(DrawingView.undo), forControlEvents: .TouchUpInside)
        
        strokeLayer.fillColor = nil
        strokeLayer.strokeColor = UIColor.blackColor().CGColor
        strokeLayer.lineWidth = 2
        
        toolbar.hidden = true
        userInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageView = UIImageView()
    let snapshotContainer = UIView()
    let strokeLayer = CAShapeLayer()
    let toolbar = UIView()
    let doneButton = UIButton()
    let undoButton = UIButton()
    let clearButton = UIButton()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        toolbar.frame = CGRectMake(0, bounds.size.height-44, bounds.size.width, 44)
        doneButton.frame = CGRectMake(toolbar.bounds.size.width-44, 0, 44, 44)
        snapshotContainer.frame = bounds
        strokeLayer.frame = snapshotContainer.bounds
        imageView.frame = bounds
        
        var x: CGFloat = 0
        for btn in [clearButton, undoButton] {
            btn.sizeToFit()
            btn.frame = CGRectMake(x, 0, btn.frame.size.width + 20, 44)
            x = btn.frame.right
        }
    }
    
    func getImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        snapshotContainer.drawViewHierarchyInRect(bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func done(sender: UIButton) {
        if let d = onDone {
            d(self)
        }
    }
    
    var item: DrawingCardItemView? {
        didSet {
            _path = item?.path ?? UIBezierPath()
        }
    }
    
    var onDone: (DrawingView -> ())?
    
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
            strokeLayer.path = _path.CGPath
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
        _path.moveToPoint(touches.first!.locationInView(self))
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        _path.addLineToPoint(touches.first!.locationInView(self))
        strokeLayer.path = _path.CGPath
        item?.path = _path
    }
    
    var drawingModeActive = false {
        didSet {
            toolbar.hidden = !drawingModeActive
            userInteractionEnabled = drawingModeActive
        }
    }
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

