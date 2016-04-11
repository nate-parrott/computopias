//
//  MessageMeCardItem.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class MessageMeCardItemView: ButtonCardItemView {
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "messageMe"
        return j
    }
    override func setup() {
        super.setup()
        title = "💬 Message"
        setCurrentPhone()
    }
    override func detachFromTemplate() {
        super.detachFromTemplate()
        setCurrentPhone()
    }
    func setCurrentPhone() {
        link = "This user has no phone number!"
        if let p = Data.getPhone() {
            let sanitizedPhone = p.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
            if sanitizedPhone.characters.count > 5 {
                link = "sms://" + p.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
            }
        }
    }
    override func edit() {
        // do nothing
    }
}
