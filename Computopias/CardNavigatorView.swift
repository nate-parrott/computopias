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
        let appearance = ElasticValue.pageValue()
    }
    
    var _stackEntries = [StackEntry]()
    
    func addStack(stack: CardStack) {
        stack.navigator = self
        let entry = StackEntry(stack: stack)
        entry.scroll.addInput(panRec) { [weak self] (let input) -> CGFloat in
            if let s = self where s._stacksToRender().last?.stack === entry.stack {
                return -(input as! UIPanGestureRecognizer).horizontalTranslationInView(s) / s.cardStride.width
            } else {
                return 0
            }
        }
        entry.appearance.addInput(panRec) { [weak self] (let input) -> CGFloat in
            if let s = self where s._stacksToRender().last?.stack === entry.stack {
                return -(input as! UIPanGestureRecognizer).verticalTranslationInView(s) / s.bounds.size.height
            } else {
                return 0
            }
        }
        
        let popOnComplete: Bool -> () = {[weak self] (_) in self?._popUnusedEntries() }
        entry.appearance.dragEndBlock = {
            (val: ElasticValue!, pos: CGFloat) in
            val.snapToPosition(round(pos), completionBlock: popOnComplete)
        }
        entry.scroll.decelerationRate = 1.5
        /*entry.scroll.dragEndBlock = {
            (let val, let suggestedLandingPos) in
            val.snapToPosition(round(suggestedLandingPos), completionBlock: nil)
        }*/
        _stackEntries.append(entry)
        stack.visible = true
        entry.appearance.max = 1
        if _stackEntries.count == 1 {
            entry.appearance.snapToPosition(1, completionBlock: nil)
            entry.appearance.min = 1
        }
    }
    
    // MARK: Public
    func pushCardStack(stack: CardStack, above: CardStack?) {
        while _stackEntries.last?.stack !== above {
            popStack()
        }
        addStack(stack)
        showStackEntryAtIndex(_stackEntries.count - 1)
    }
    
    func popStack() {
        let entry = _stackEntries.removeLast()
        entry.stack.visible = false
        entry.stack.navigator = nil
        entry.scroll.removeInput(panRec)
    }
    
    // MARK: Internal
    func _stacksToRender() -> [StackEntry] {
        var toRender = [StackEntry]()
        for entry in _stackEntries {
            if entry.appearance.rubberBandedPosition >= 1 {
                toRender.removeAll()
            }
            if entry.appearance.rubberBandedPosition > 0 {
                toRender.append(entry)
            }
        }
        return toRender
    }
    
    func showStackEntryAtIndex(index: Int) {
        _stackEntries[index].appearance.snapToPosition(1, spring: true, completionBlock: nil)
        var i = index+1
        while i < _stackEntries.count {
            _stackEntries[i].appearance.snapToPosition(0, spring: false, completionBlock: nil)
            i += 1
        }
    }
    
    
    var cardSize = CGSizeMake(300, 400)
    let panRec = UIPanGestureRecognizer()
    
    override func elasticSetup() {
        super.elasticSetup()
        addGestureRecognizer(panRec)
        // stackLevel.logName = "level"
        /*stackLevel.addInput(panRec) { [weak self] (let input) -> CGFloat in
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
        stackLevel.decelerationRate = 2*/
    }
    
    var cardStride: CGSize {
        get {
            return CGSizeMake(cardSize.width + 20, cardSize.height + (bounds.height - cardSize.height)/2)
        }
    }
    
    func _popUnusedEntries() {
        while _stackEntries.last?.appearance.position <= 0 && _stackEntries.count > 1 {
            popStack()
        }
    }
    
    var _cardCentersForThisRender = [String: CGPoint]()
    
    override func elasticRender() {
        super.elasticRender()
        _cardCentersForThisRender.removeAll()
        
        for entry in _stackEntries {
            entry.scroll.max = CGFloat(entry.stack.cardModels.count - 1)
        }
        
        /*for i in 0..<lowerStackIndex {
            _renderStack(i, yOffset: 1) // render lower layers (should we?)
        }*/
        for entry in _stacksToRender() {
            let i = _stackEntries.indexOf({ $0.stack === entry.stack })!
            _renderStack(i, yOffset: 1 - entry.appearance.rubberBandedPosition)
        }
    }
    
    func _renderStack(index: Int, yOffset: CGFloat) {
        if index < _stackEntries.count && index >= 0 {
            let entry = _stackEntries[index]
            let stack = entry.stack
            let scroll = entry.scroll
            let stride = cardStride
            let center = CGPointMake(bounds.center.x - scroll.rubberBandedPosition * stride.width, bounds.center.y + yOffset * stride.height)
            let obscuredAmount = _getObscuredAmountForStackAtIndex(index)
            
            // render background:
            let background = elasticGetChildWithKey("background-\(index)", creationBlock: { () -> UIView! in
                return UIView()
            }) as! UIView
            background.backgroundColor = stack.backgroundColor
            background.frame = CGRectMake(0, yOffset * bounds.size.height, bounds.size.width, bounds.size.height)
            if stack.tintColor != background.tintColor {
                background.tintColor = stack.tintColor
            }
            
            // render title:
            let barHeight = (bounds.size.height - cardSize.height)/2
            let title = background.elasticGetChildWithKey("title", creationBlock: { () -> UIView! in
                let l = UILabel()
                l.textAlignment = .Center
                l.textColor = stack.textColor
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
                let offsetEased = EVQuadraticEaseOut(yOffset) * 0.5 + yOffset * 0.5
                let cardCenter = CGPointMake(center.x + stride.width * CGFloat(index), background.bounds.height/2 - background.frame.origin.y + offsetEased * background.frame.size.height)
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
                    view.transform = CGAffineTransformIdentity
                    view.frame = frame
                    view.transform = CGAffineTransformMakeScale(1 - obscuredAmount * 0.3, 1 - obscuredAmount * 0.3)
                    /*if yOffset > 0, let prevPoint = self._cardCentersForThisRender[model as! String] {
                        view.center = EVInterpolatePoint(prevPoint, frame.center, 1 - yOffset)
                    }
                    self._cardCentersForThisRender[model as! String] = view.frame.center*/
            })
        }
    }
    
    func _getObscuredAmountForStackAtIndex(index: Int) -> CGFloat {
        var o: CGFloat = 0
        for i in index+1..<_stackEntries.count {
            o = max(o, _stackEntries[i].appearance.rubberBandedPosition)
        }
        return o
    }
}


