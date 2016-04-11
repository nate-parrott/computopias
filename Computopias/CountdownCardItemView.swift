//
//  CountdownCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class CountdownCardItemView: CardItemView {
    /*let label = UILabel()
    let imageView = UIImageView(image: UIImage(named: "stopwatch"))
    
    override func setup() {
        super.setup()
        addSubview(label)
        label.textAlignment = .Center
        label.font = TextCardItemView.font
        _update()
        addSubview(imageView)
        imageView.contentMode = .ScaleAspectFit
        imageView.tintColor = UIColor.blackColor()
        imageView.alpha = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
        imageView.frame = bounds
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "countdown"
        j["seconds"] = seconds
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        seconds = json["seconds"] as? Int ?? 5
    }
    var seconds = 5 {
        didSet {
            _update()
        }
    }
    var elapsed = 0 {
        didSet {
            _update()
        }
    }
    override var defaultSize: GridSize {
        get {
            return CGSize(width: 1, height: 1)
        }
    }
    override func prepareToPresent() {
        super.prepareToPresent()
        delay(1) { 
            self.countdown()
        }
    }
    
    override func tapped() -> Bool {
        super.tapped()
        if editMode {
            let alert = UIAlertController(title: "Countdown Timer", message: "The card becomes blank after this amount of time:", preferredStyle: .Alert)
            for i in 1...8 {
                let addOptionForSeconds: (Int -> ()) = { (i: Int) in
                    alert.addAction(UIAlertAction(title: "\(i) seconds", style: .Default, handler: { (let handler) in
                    self.seconds = i
                    }))
                }
                addOptionForSeconds(i)
            }
            presentViewController(alert)
            return true
        }
        return false
    }
    
    func _update() {
        label.text = "\(seconds-elapsed)"
    }
    
    func countdown() {
        elapsed += 1
        if seconds == elapsed {
            card?.blackOut()
        } else if elapsed < seconds && superview != nil {
            delay(1, closure: { 
                self.countdown()
            })
        }
    }*/
}
