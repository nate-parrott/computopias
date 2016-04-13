//
//  UIWindow+ParticleEffects.swift
//  ImageCascadeEffects
//
//  Created by Nate Parrott on 4/11/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIView {
    func fireTouchParticleEffectAtPoint(pt: CGPoint, image: UIImage) {
        let layer = CAEmitterLayer()
        let cell = CAEmitterCell()
        cell.contents = image.CGImage
        cell.scaleRange = 0.7
        cell.scaleSpeed = -0.1
        cell.scale = 1
        cell.yAcceleration = -400
        cell.velocity = 90
        cell.emissionLongitude = CGFloat(-M_PI/2)
        cell.emissionRange = CGFloat(M_PI) * 2.0 * 0.6
        cell.velocityRange = 40
        // cell.emissionRange = CGFloat(M_PI * 2)
        cell.lifetime = 3
        cell.birthRate = 20 / 0.04
        cell.spinRange = CGFloat(M_PI)
        layer.scale = 0.3
        layer.emitterCells = [cell]
        layer.emitterShape = kCAEmitterLayerCircle
        layer.emitterSize = CGSizeMake(15, 15)
        layer.beginTime = CACurrentMediaTime()
        let speed: Float = 1.5
        layer.speed = speed
        delay(0.04 / Double(speed)) {
            layer.birthRate = 0
        }
        delay(3.5 / Double(speed)) {
            layer.removeFromSuperlayer()
        }
        window!.layer.addSublayer(layer)
        layer.position = convertPoint(pt, toView: window!)
    }
    func fireTouchParticleEffectAtPoint2(pt: CGPoint, image: UIImage) {
        let layer = CAEmitterLayer()
        let cell = CAEmitterCell()
        cell.contents = image.CGImage
        cell.alphaRange = 0.1
        cell.alphaSpeed = -1
        cell.scaleRange = 0.4
        cell.scaleSpeed = 0.7
        cell.scale = 0
        cell.yAcceleration = -200
        cell.velocity = 90
        cell.emissionLongitude = CGFloat(-M_PI/2)
        cell.emissionRange = CGFloat(M_PI) * 2.0 * 0.2
        cell.velocityRange = 20
        // cell.emissionRange = CGFloat(M_PI * 2)
        cell.lifetime = 2
        cell.birthRate = 60
        cell.spinRange = CGFloat(M_PI)
        layer.scale = 0.3
        layer.emitterCells = [cell]
        layer.emitterShape = kCAEmitterLayerCircle
        layer.emitterSize = CGSizeMake(40, 40)
        layer.beginTime = CACurrentMediaTime()
        let speed: Float = 1.5
        layer.speed = speed
        delay(0.5 / Double(speed)) {
            layer.birthRate = 0.25
        }
        delay(1 / Double(speed)) {
            layer.birthRate = 0
            layer.scale = 0.25
            // cell.color = UIColor(white: 1, alpha: 0.5).CGColor
        }
        delay(3) {
            layer.removeFromSuperlayer()
        }
        window!.layer.addSublayer(layer)
        layer.position = convertPoint(pt, toView: window!)
    }
}
