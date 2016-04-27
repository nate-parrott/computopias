//
//  LargeTextCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 4/26/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class LargeTextCardItemView: CardItemView {
    override func setup() {
        super.setup()
        layerBacked = false
        opaque = false
        needsDisplayOnBoundsChange = true
    }
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(-1, 2)
        }
    }
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    let defaultText = "Tap to edit…"
    var text = "Tap to edit…" {
        didSet {
            setNeedsDisplay()
        }
    }
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "largeText"
        j["text"] = text
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        text = json["text"] as? String ?? ""
    }
    override func tapped() -> Bool {
        if editMode {
            let a = UIAlertController(title: "Edit Text", message: nil, preferredStyle: .Alert)
            a.addTextFieldWithConfigurationHandler({ (let field) in
                if self.text != self.defaultText {
                    field.text = self.text
                }
            })
            a.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (_) in
                
            }))
            a.addAction(UIAlertAction(title: "Done", style: .Default, handler: { [weak a] (_) in
                self.text = a!.textFields!.first!.text ?? ""
            }))
            NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(a, animated: true, completion: nil)
            return true
        }
        return false
    }
    
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        return text as NSString
    }
    
    // + (void)drawRect:(CGRect)bounds withParameters:(nullable id <NSObject>)parameters
    // isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock
    // isRasterizing:(BOOL)isRasterizing;
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let text = withParameters! as! String
        let string = NSAttributedString(string: text, attributes: [NSParagraphStyleAttributeName: NSAttributedString.paragraphStyleWithTextAlignment(.Center), NSFontAttributeName: TextCardItemView.boldFont])
        string.drawFillingRect(CardItemView.textInsetBoundsForBounds(bounds))
    }
}
