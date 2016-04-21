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
    case Profile(id: String)
    case ProfilesList
    case HashtagsList
    case Activity
    case CreateGroup
    case Nothing
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
            case .Profile(id: let id):
                urlComps.path = "/profiles/" + id
            default: ()
            }
            return urlComps.URL!
        }
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
        } else if parts.count == 2 && parts[0] == "profiles" {
            return Route.Profile(id: parts[1])
        }
        return nil
    }
}
