//
//  Cards.swift
//  Computopias
//
//  Created by Nate Parrott on 3/30/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

extension Data {
    static func cardJson(cardID: String, hashtag: String) -> [String: AnyObject] {
        return ["cardID": cardID, "hashtag": hashtag, "poster": profileJson(), "negativeDate": -NSDate().timeIntervalSince1970, "date": NSDate().timeIntervalSince1970]
    }
}
