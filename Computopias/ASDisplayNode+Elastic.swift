//
//  ASDisplayNode+Elastic.swift
//  Computopias
//
//  Created by Nate Parrott on 4/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

extension ASDisplayNode: ElasticRenderedObject {
    public func elastic_moveToFront() {
        
    }
    public func elastic_addToSuperview(superview: UIView) {
        if let node = ASViewToDisplayNode(superview) {
            node.addSubnode(self)
        } else if layerBacked {
            superview.layer.addSublayer(layer)
        } else {
            superview.addSubview(view)
        }
    }
    public func elastic_removeFromSuperview() {
        if supernode != nil {
            removeFromSupernode()
        } else if layerBacked {
            layer.removeFromSuperlayer()
        } else {
            view.removeFromSuperview()
        }
    }
}
