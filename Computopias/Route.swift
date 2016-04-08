//
//  Route.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

enum Route {
    case Hashtag(name: String)
    case Card(hashtag: String, id: String)
    case ProfilesList
    case HashtagsList
    case Activity
    case CreateGroup
    case Nothing
    var string: String {
        get {
            switch self {
            case .Hashtag(name: let h): return "#" + h
            case .Card(hashtag: let hashtag, id: let id): return "#" + hashtag + "/" + id
            case .HashtagsList: return "!hashtags"
            case .ProfilesList: return "!profiles"
            case .CreateGroup: return "!create"
            case .Activity: return "!activity"
            default: return ""
            }
        }
    }
    var titleStringForNav: String {
        get {
            switch self {
            case .Card(hashtag: let hashtag, id: _): return "#" + hashtag
            case .Hashtag(name: let hashtag): return "#" + hashtag
            default: return ""
            }
        }
    }
    var url: NSURL {
        get {
            let urlComps = NSURLComponents(string: "bubble://x")!
            switch self {
            case .Hashtag(name: let name):
                urlComps.path = "/groups/" + name
            case .Card(hashtag: let hashtag, id: let id):
                urlComps.path = "/groups/" + hashtag + "/" + id
            case .ProfilesList:
                urlComps.path = "/friends"
            case .HashtagsList:
                urlComps.path = "/feed"
            case .CreateGroup:
                urlComps.path = "/create"
            case .Activity:
                urlComps.path = "/activity"
            default: ()
            }
            return urlComps.URL!
        }
    }
    // TOOD: remove this, replace w/ urls
    static func fromString(string: String) -> Route? {
        if string == "!hashtags" {
            return  Route.HashtagsList
        } else if string == "!profiles" {
            return Route.ProfilesList
        } else if string == "!activity" {
            return Route.Activity
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
        }
        return nil
    }
    static func fromURL(url: NSURL) -> Route? {
        var parts = url.pathComponents ?? []
        if parts.first == "/" { parts.removeAtIndex(0) }
        if parts.count == 2 && parts[0] == "groups" {
            return Route.Hashtag(name: parts[1])
        } else if parts.count == 3 && parts[0] == "groups" {
            return Route.Card(hashtag: parts[1], id: parts[2])
        } else if parts.count == 1 && parts[0] == "feed" {
            return Route.HashtagsList
        } else if parts.count == 1 && parts[0] == "friends" {
            return Route.ProfilesList
        } else if parts.count == 1 && parts[0] == "create" {
            return Route.CreateGroup
        } else if parts.count == 1 && parts[0] == "activity" {
            return Route.Activity
        }
        return nil
    }
    static func forProfile(uid: String) -> Route {
        return Route.Card(hashtag: "profiles", id: uid)
    }
}
