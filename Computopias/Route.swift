//
//  Route.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

enum Route {
    case Profile(name: String)
    case Hashtag(name: String)
    case Card(hashtag: String, id: String)
    case Home
    case Nothing
    var string: String {
        get {
            switch self {
            case .Profile(name: let p): return "@" + p
            case .Hashtag(name: let h): return "#" + h
            case .Card(hashtag: let hashtag, id: let id): return "#" + hashtag + "/" + id
            case .Home: return ""
            default: return ""
            }
        }
    }
    static func fromString(string: String) -> Route {
        if string == "" {
            return Route.Home
        } else if string.characters.first! == "@".characters.first! {
            return Route.Profile(name: string[1...string.characters.count])
        } else if string.characters.first! == "#".characters.first! {
            let parts = string.componentsSeparatedByString("/")
            if parts.count == 2 {
                return Route.Card(hashtag: parts[0][1..<parts[0].characters.count], id: parts[1])
            } else {
                return Route.Hashtag(name: string[1..<string.characters.count])
            }
        } else if string.componentsSeparatedByString(" ").count == 1 {
            // assume hashtag:
            return Route.Hashtag(name: string)
        } else {
            return Route.Nothing
        }
    }
}
