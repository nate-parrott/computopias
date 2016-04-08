//
//  CardNavigatorView.swift
//  Elastic
//
//  Created by Nate Parrott on 4/6/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CardNavigatorView: UIView {
    struct StackEntry {
        let stack: CardStack
        let scroll = ElasticValue.pageValue()
    }
    
    var _stackEntries = [StackEntry]()
    let stackLevel = ElasticValue.pageValue()
    
    func addStack(stack: CardStack) {
        stack.navigator = self
        let idx = _stackEntries.count
        let entry = StackEntry(stack: stack)
        entry.scroll.addInput(panRec) { [weak self] (let input) -> CGFloat in
            if let s = self where Int(round(s.stackLevel.position)) == idx {
                return -(input as! UIPanGestureRecognizer).horizontalTranslationInView(s) / s.cardStride.width
            } else {
                return 0
            }
        }
        entry.scroll.decelerationRate = 1.5
        entry.scroll.dragEndBlock = {
            (let val, let suggestedLandingPos) in
            val.snapToPosition(round(suggestedLandingPos), completionBlock: nil)
        }
        _stackEntries.append(entry)
        stack.visible = true
    }
    
    func pushCardStack(stack: CardStack, above: CardStack?) {
        while _stackEntries.last?.stack !== above {
            popStack()
        }
        addStack(stack)
        stackLevel.snapToPosition(CGFloat(_stackEntries.count-1), spring: true, completionBlock: nil)
    }
    
    func popStack() {
        let entry = _stackEntries.removeLast()
        entry.stack.visible = false
        entry.stack.navigator = nil
        entry.scroll.removeInput(panRec)
    }
    
    
    var cardSize = CGSizeMake(300, 400)
    let panRec = UIPanGestureRecognizer()
    
    override func elasticSetup() {
        super.elasticSetup()
        addGestureRecognizer(panRec)
        stackLevel.addInput(panRec) { [weak self] (let input) -> CGFloat in
            if let s = self {
                return -(input as! UIPanGestureRecognizer).verticalTranslationInView(s) / s.bounds.size.height
            } else {
                return 0
            }
        }
        stackLevel.dragEndBlock = {
            (let val, let suggestedLandingPos) in
            val.snapToPosition(round(suggestedLandingPos), completionBlock: {
                [weak self] _ in
                self?._popUnusedEntries()
            })
        }
        stackLevel.decelerationRate = 2
    }
    
    var cardStride: CGSize {
        get {
            return CGSizeMake(cardSize.width + 20, cardSize.height + (bounds.height - cardSize.height)/2)
        }
    }
    
    func _popUnusedEntries() {
        while _stackEntries.count - 1 > Int(ceil(stackLevel.position)) {
            popStack()
        }
    }
    
    var _cardCentersForThisRender = [String: CGPoint]()
    
    override func elasticRender() {
        super.elasticRender()
        _cardCentersForThisRender.removeAll()
        
        stackLevel.max = CGFloat(_stackEntries.count - 1)
        
        for entry in _stackEntries {
            entry.scroll.max = CGFloat(entry.stack.cardModels.count - 1)
        }
        
        let lowerStackIndex = Int(floor(stackLevel.position))
        let isTop = (lowerStackIndex + 1 == _stackEntries.count)
        _renderStack(lowerStackIndex, yOffset: isTop ? CGFloat(lowerStackIndex) - stackLevel.position : 0)
        if CGFloat(lowerStackIndex) != stackLevel.position {
            _renderStack(lowerStackIndex+1, yOffset: CGFloat(lowerStackIndex+1) - stackLevel.position)
        }
    }
    
    func _renderStack(index: Int, yOffset: CGFloat) {
        if index < _stackEntries.count && index >= 0 {
            let entry = _stackEntries[index]
            let stack = entry.stack
            let scroll = entry.scroll
            let stride = cardStride
            let center = CGPointMake(bounds.center.x - scroll.position * stride.width, bounds.center.y + yOffset * stride.height)
            
            // render background:
            let background = elasticGetChildWithKey("background-\(index)", creationBlock: { () -> UIView! in
                return UIView()
            }) as! UIView
            background.backgroundColor = stack.backgroundColor
            background.frame = CGRectMake(0, yOffset * bounds.size.height, bounds.size.width, bounds.size.height)
            
            // render title:
            let barHeight = (bounds.size.height - cardSize.height)/2
            let title = background.elasticGetChildWithKey("title", creationBlock: { () -> UIView! in
                let l = UILabel()
                l.textAlignment = .Center
                l.textColor = UIColor(white: 0.1, alpha: 0.5)
                l.font = UIFont.systemFontOfSize(21, weight: UIFontWeightLight)
                return l
            }) as! UILabel
            title.text = stack.title
            title.frame = CGRectMake(0, 0, bounds.size.width, barHeight)
            
            // render controls:
            stack.renderTopControls(background, rect: CGRectMake(0, 0, background.bounds.width, barHeight))
            stack.renderBottomControls(background, rect: CGRectMake(0, background.bounds.height - barHeight, background.bounds.width, barHeight))
            
            let frameFunc = {
                (index: Int) -> CGRect in
                let cardCenter = CGPointMake(center.x + stride.width * CGFloat(index), background.bounds.height / 2)
                return CGRectMake(cardCenter.x - self.cardSize.width/2, cardCenter.y - self.cardSize.height/2, self.cardSize.width, self.cardSize.height)
            }
            
            background.elasticRenderModels(stack.cardModels, positionBlock: { (_, let index) -> ElasticLayoutModelPosition in
                let frame = frameFunc(index)
                if CGRectIntersectsRect(frame, self.bounds) {
                    return ElasticLayoutModelPosition.Onscreen
                } else if frame.origin.x < self.bounds.origin.x {
                    return ElasticLayoutModelPosition.BeforeScreen
                } else {
                    return ElasticLayoutModelPosition.AfterScreen
                }
                }, renderBlock: { (let model, let index) in
                    let frame = frameFunc(index)
                    let view = background.elasticGetChildWithKey(model as! String, creationBlock: { () -> UIView! in
                        let card = stack.createCard(model as! String)
                        stack.renderCard(model as! String, view: card)
                        return card
                    }) as! UIView
                    view.frame = frame
                    /*if yOffset > 0, let prevPoint = self._cardCentersForThisRender[model as! String] {
                        view.center = EVInterpolatePoint(prevPoint, frame.center, 1 - yOffset)
                    }
                    self._cardCentersForThisRender[model as! String] = view.frame.center*/
            })
        }
    }
}


