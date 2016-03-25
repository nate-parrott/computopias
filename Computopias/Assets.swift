//
//  Assets.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

struct Assets {
    // MARK: Assets
    static let _servicesURL = "https://surfboard-services.appspot.com"
    
    static func uploadAsset(data: NSData, contentType: String, callback: (url: NSURL?, error: NSError?) -> ()) {
        let urlComps = NSURLComponents(string: _servicesURL + "/raw_upload")!
        urlComps.queryItems = [NSURLQueryItem(name: "content_type", value: contentType)]
        let req = NSMutableURLRequest(URL: urlComps.URL!)
        req.HTTPMethod = "POST"
        req.HTTPBody = data
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(req) { (dataOpt, responseOpt, errorOpt) -> Void in
            if let data = dataOpt,
                response = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
                responseDict = response as? [String: AnyObject],
                urlString = responseDict["url"] as? String,
                url = NSURL(string: urlString) {
                mainThread({ 
                    callback(url: url, error: nil)
                })
            } else {
                mainThread({ 
                    callback(url: nil, error: errorOpt)
                })
            }
        }
        task.resume()
    }
    
    static func mirrorURLForImage(url: String, width: CGFloat) -> NSURL {
        let comps = NSURLComponents(string: _servicesURL + "/mirror")!
        let w = Int(width)
        let h = w * 3
        comps.queryItems = [NSURLQueryItem(name: "url", value: url), NSURLQueryItem(name: "resize", value: "\(w),\(h)")]
        return comps.URL!
    }
    
    static func fetch(url: NSURL, callback: (data: NSData?, error: NSError?) -> ()) -> NSURLSessionDataTask {
        let req = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(req) { (let dataOpt, let respOpt, let errorOpt) in
            callback(data: dataOpt, error: errorOpt)
        }
        task.resume()
        return task
    }
}
