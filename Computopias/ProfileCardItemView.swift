//
//  ProfileCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ProfileCardItemView: CardItemView {
    override func setup() {
        super.setup()
        profileDict = Data.profileJson()
        addSubview(label)
        label.font = TextCardItemView.font
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = textInsetBounds
        label.font = TextCardItemView.font.fontWithSize(generousFontSize)
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        profileDict = json["profile"] as? [String: AnyObject]
    }
    
    var profileDict: [String: AnyObject]! {
        didSet {
            if let name = profileDict["name"] as? String {
                label.text = "👤 " + name
            }
        }
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "profile"
        if let d = profileDict {
            j["profile"] = d
        }
        return j
    }
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(3, 1)
        }
    }
    let label = UILabel()
    override func detachFromTemplate() {
        super.detachFromTemplate()
        profileDict = Data.profileJson()
    }
    
    override func tapped() -> Bool {
        super.tapped()
        if !editMode {
            // NavViewController.shared.navigate("@" + (profileDict["uid"] as? String ?? ""))
            return true
        }
        return false
    }
}
