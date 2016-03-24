//
//  SoundCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SoundCardItemView: CardItemView {
    override func setup() {
        super.setup()
        label.font = TextCardItemView.font
        addSubview(label)
        label.textAlignment = .Center
        _updateText()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    var url: String? {
        didSet {
            _updateText()
        }
    }
    var duration: Double?
    var loop = false
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "sound"
        if let u = url {
            j["url"] = u
        }
        if let d = duration {
            j["duration"] = d
        }
        j["loop"] = loop
        return j
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        url = json["url"] as? String ?? url
        loop = json["loop"] as? Bool ?? loop
        duration = json["duration"] as? Double ?? duration
    }
    let label = UILabel()
    var nowPlaying = false {
        didSet {
            _updateText()
        }
    }
    func _updateText() {
        label.alpha = 1
        if nowPlaying {
            label.text = "🔊"
        } else if url != nil {
            label.text = "🔈"
        } else {
            label.text = "🔈"
            label.alpha = 0.5
        }
    }
    override func tapped() {
        super.tapped()
        if editMode {
            // TODO: launch editor
        } else {
            // TODO: toggle playback
        }
    }
}
