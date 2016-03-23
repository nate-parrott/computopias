//
//  NetImageView.swift
//  ptrptr
//
//  Created by Nate Parrott on 1/16/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NetImageView: UIImageView {
    private var _url: NSURL?
    var url: NSURL? {
        set(val) {
            setURL(val, placeholder: nil)
        }
        get {
            return _url
        }
    }
    
    func setURL(newURL: NSURL?, placeholder: UIImage?) {
        if newURL != _url {
            _url = newURL
            image = placeholder
            NetImageView.cleanImageCache()
            _task?.cancel()
            _task = nil
            loadInProgress = false
            
            if let url_ = newURL {
                let cacheID = url_.absoluteString
                if let cached = NetImageView.imageCache[cacheID]?.image {
                    image = cached
                } else {
                    loadInProgress = true
                    let req = NSMutableURLRequest(URL: url_)
                    req.cachePolicy = .ReturnCacheDataElseLoad
                    _task = NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { [weak self] (let dataOpt, let responseOpt, let errorOpt) -> Void in
                        backgroundThread({ () -> Void in
                            // sleep(1)
                            if let self_ = self, data = dataOpt, let image = UIImage(data: data) {
                                mainThread({ () -> Void in
                                    if self_.url == url_ {
                                        UIView.transitionWithView(self_, duration: 0.15, options: [.AllowUserInteraction, .TransitionCrossDissolve], animations: { () -> Void in
                                            self_.image = image
                                            }, completion: nil)
                                        
                                        let weakImage = WeakImage()
                                        weakImage.image = image
                                        NetImageView.imageCache[cacheID] = weakImage
                                        
                                        self_.loadInProgress = false
                                    }
                                })
                            }
                        })
                        })
                    self._task!.resume()
                }
            }
        } else {
            loadInProgress = false
        }
    }
    
    var _task: NSURLSessionDataTask?
    
    static var imageCache = [String: WeakImage]()
    static func cleanImageCache() {
        var keysToRemove = [String]()
        for (id, weakImage) in imageCache {
            if weakImage.image == nil {
                keysToRemove.append(id)
            }
        }
        for key in keysToRemove {
            imageCache.removeValueForKey(key)
        }
    }
    class WeakImage {
        weak var image: UIImage?
    }
    
    private(set) var loadInProgress = false {
        didSet {
            backgroundColor = loadInProgress ? UIColor(white: 0.5, alpha: 0.5) : UIColor.clearColor()
        }
    }
}
