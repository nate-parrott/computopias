//
//  SitePreviewInfo.swift
//  Computopias
//
//  Created by Nate Parrott on 6/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

struct SitePreview {
    let canonicalURL: NSURL
    let title: String?
    let previewImageURL: String?
    let description: String?
    static func fetch(url: String, callback: (url: String, preview: SitePreview?) -> ()) {
        guard let siteURL = NSURL(string: url) else {
            callback(url: url, preview: nil)
            return
        }
        let base = "https://stacks-app.appspot.com/site_preview"
        let comps = NSURLComponents(string: base)!
        comps.queryItems = [NSURLQueryItem(name: "url", value: url)]
        let task = NSURLSession.sharedSession().dataTaskWithURL(comps.URL!) { (let dataOpt, _, _) in
            if let data = dataOpt, let resultObj = try? NSJSONSerialization.JSONObjectWithData(data, options: []), let result = resultObj as? [String: AnyObject] {
                let canonicalURL: NSURL?
                if let s = result["url"] as? String {
                    canonicalURL = NSURL(string: s)
                } else {
                    canonicalURL = nil
                }
                let preview = SitePreview(
                    canonicalURL: canonicalURL ?? siteURL,
                    title: result["title"] as? String,
                    previewImageURL: result["image"] as? String,
                    description: result["description"] as? String)
                callback(url: url, preview: preview)
            } else {
                callback(url: url, preview: nil)
            }
        }
        task.resume()
    }
}
