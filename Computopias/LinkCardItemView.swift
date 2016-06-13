//
//  LinkCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 6/10/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import SafariServices

class LinkCardItemView: CardItemView {
    // MARK: Data
    struct SiteInfo {
        let url: String
        let title: String?
        let desc: String?
        let displayURL: String?
        let imageURL: String?
    }
    var siteInfo: SiteInfo? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Preview image loading
    enum ImageLoadState {
        case None
        case Loading(url: String, task: NSURLSessionDataTask)
        case Finished(url: String, image: UIImage?)
        var url: String? {
            get {
                switch self {
                case .Loading(url: let u, task: _): return u
                case .Finished(url: let u, image: _): return u
                default: return nil
                }
            }
        }
    }
    var _imageLoadState = ImageLoadState.None {
        didSet {
            setNeedsDisplay()
        }
    }
    var _previewImageLoadingTask: NSURLSessionDataTask?
    func _loadPreviewImage() {
        let urlOpt = siteInfo?.imageURL
        if urlOpt != _imageLoadState.url {
            _cancelImageLoad()
            if let url = urlOpt where NSURL(string: url) != nil {
                let fetchURL = Assets.mirrorURLForImage(url, width: 600)
                let task = NSURLSession.sharedSession().dataTaskWithURL(fetchURL, completionHandler: { [weak self] (let dataOpt, _, _) in
                    var img: UIImage?
                    if let d = dataOpt, let image = UIImage(data: d) {
                        img = image
                    }
                    mainThread({ 
                        self?._imageLoadState = .Finished(url: url, image: img)
                    })
                })
                _imageLoadState = .Loading(url: url, task: task)
                task.resume()
            }
        }
    }
    func _cancelImageLoad() {
        switch _imageLoadState {
        case .Loading(url: _, task: let task):
            task.cancel()
        default: ()
        }
        _imageLoadState = .None
    }
    
    // MARK: Lifecycle
    override func setup() {
        super.setup()
        needsDisplayOnBoundsChange = true
        opaque = false
        clipsToBounds = true
        cornerRadius = CardView.rounding
    }
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        if let url = json["url"] as? String {
            siteInfo = SiteInfo(url: url, title: json["title"] as? String, desc: json["desc"] as? String, displayURL: json["display_url"] as? String, imageURL: json["image_url"] as? String)
            _loadPreviewImage()
        }
    }
    
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "link"
        if let i = siteInfo {
            j["url"] = i.url
            if let t = i.title { j["title"] = t }
            if let d = i.desc { j["desc"] = d }
            if let u = i.displayURL { j["display_url"] = u }
            if let img = i.imageURL { j["image_url"] = img }
        }
        return j
    }
    
    override func onInsert() {
        super.onInsert()
        pickURL()
    }
    
    // MARK: Layout
    override var defaultSize: GridSize {
        get {
            return GridSize(width: 4, height: 2)
        }
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    
    // MARK: Interaction
    override func tapped() -> Bool {
        if editMode {
            pickURL()
            return true
        } else {
            if let link = siteInfo?.url {
                openLink(link)
                return true
            } else {
                return false
            }
        }
    }
    
    func pickURL() {
        let alert = UIAlertController(title: "Set Link URL", message: "Paste the URL for the page you'd like to link to:", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) in
            field.keyboardType = .URL
            field.placeholder = self.siteInfo?.url ?? "http://nytimes.com"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Make Link", style: .Default, handler: { (_) in
            var urlString = alert.textFields!.first!.text ?? ""
            if urlString != "" {
                let isHashtag = urlString.rangeOfString("#")?.startIndex == urlString.startIndex
                if urlString.rangeOfString("://") == nil && !isHashtag {
                    urlString = "http://" + urlString
                }
                if NSURL(string: urlString) != nil {
                    self.pickedURL(urlString)
                }
            }
        }))
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(alert, animated: true, completion: nil)
    }
    
    func pickedURL(url: String) {
        siteInfo = SiteInfo(url: url, title: nil, desc: nil, displayURL: nil, imageURL: nil)
        _imageLoadState = .None
        // fetch site preview info:
        SitePreview.fetch(url) { (url, preview) in
            mainThread({ 
                if let p = preview where url == self.siteInfo?.url {
                    self.siteInfo = SiteInfo(url: url, title: p.title, desc: p.description, displayURL: p.canonicalURL.absoluteString, imageURL: p.previewImageURL)
                    self._loadPreviewImage()
                }
            })
        }
    }
    
    // MARK: Link opening
    func openLink(link: String) {
        print("opening link: \(link)")
        if let firstChar = link.characters.first {
            if firstChar == "#".characters.first! {
                let s = link[1..<link.characters.count]
                (UIApplication.sharedApplication().delegate as! AppDelegate).navigateToRoute(Route.Hashtag(name: s))
            } else {
                var isURL = false
                if link.componentsSeparatedByString(" ").count > 1 {
                    isURL = false
                } else if let u = NSURL(string: link) where u.scheme != "" {
                    isURL = true
                } else if link.componentsSeparatedByString(".").count > 1 {
                    isURL = true
                }
                
                if link.componentsSeparatedByString(" ").count > 1 {
                    isURL = false
                }
                if link.componentsSeparatedByString(".").count == 1 {
                    isURL = false
                }
                if link.hasPrefix("sms://") || link.hasPrefix("bubble://") {
                    isURL = true
                }
                if isURL {
                    if var url = NSURL(string: link) {
                        if url.scheme == "" {
                            url = NSURL(string: "http://" + link)!
                        }
                        if url.scheme == "http" || url.scheme == "https" {
                            let safari = SFSafariViewController(URL: url)
                            presentViewController(safari)
                        } else {
                            UIApplication.sharedApplication().openURL(url)
                        }
                    }
                } else {
                    let alertVC = UIAlertController(title: nil, message: link, preferredStyle: .Alert)
                    alertVC.addAction(UIAlertAction(title: "Done", style: .Default, handler: { (_) in
                        
                    }))
                    presentViewController(alertVC)
                }
            }
        }
    }
    
    // MARK: Rendering
    override var needsNoView: Bool {
        get {
            return true
        }
    }
    
    class DrawParams: NSObject {
        var siteInfo: SiteInfo?
        var previewImage: UIImage?
        var siteString: String {
            get {
                if let info = siteInfo {
                    let absoluteString = info.displayURL ?? info.url
                    if let comps = NSURLComponents(string: absoluteString) where comps.host != nil {
                        return comps.host!
                    }
                    return absoluteString
                }
                return ""
            }
        }
    }
    
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        let d = DrawParams()
        d.siteInfo = siteInfo
        switch _imageLoadState {
        case .Finished(url: _, image: let img):
            d.previewImage = img
        default: ()
        }
        return d
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let params = withParameters as! DrawParams
        if let img = params.previewImage {
            let scale = max(bounds.size.width / img.size.width, bounds.size.height / img.size.height)
            img.drawInRect(CGRect(center: bounds.center, size: img.size * scale).integral)
        } else {
            let backgroundColor = UIColor(red: 0.949949204922, green:0.949971497059, blue:0.949959456921, alpha:1.0)
            backgroundColor.setFill()
            UIBezierPath(rect: bounds).fill()
            
            let linkImage = UIImage(named: "BigLinkIcon")!
            let linkImageContentSize = CGSizeMake(min(70, bounds.size.width * 0.7), min(70, bounds.size.height * 0.7))
            let scale = min(linkImageContentSize.width / linkImage.size.width, linkImageContentSize.height / linkImage.size.height)
            linkImage.drawInRect(CGRect(center: bounds.center, size: linkImage.size * scale).integral, blendMode: .Normal, alpha: 0.35)
        }
        
        let size = min(bounds.size.width, bounds.size.height)
        let scale: CGFloat
        if size > 150 {
            scale = 14
        } else if size > 40 {
            scale = 12
        } else {
            scale = 9
        }
        let siteSize = scale
        let titleSize = round(scale * 1.33)
        
        let padding = round(scale / 3)
        
        let drawSiteName = bounds.size.height > 60
        if drawSiteName {
            var siteAttributes = [String: AnyObject]()
            siteAttributes[NSForegroundColorAttributeName] = params.previewImage == nil ? UIColor.blackColor() : UIColor.whiteColor()
            siteAttributes[NSFontAttributeName] = TextCardItemView.boldFont.fontWithSize(siteSize)
            siteAttributes[NSParagraphStyleAttributeName] = NSAttributedString.paragraphStyleWithTextAlignment(.Right)
            if params.previewImage != nil {
                let shadow = NSShadow()
                shadow.shadowOffset = CGSizeZero
                shadow.shadowBlurRadius = siteSize / 3
                shadow.shadowColor = UIColor.blackColor()
                siteAttributes[NSShadowAttributeName] = shadow
            }
            let str = NSAttributedString(string: params.siteString, attributes: siteAttributes)
            str.drawInRect(CGRectInset(bounds, padding, padding))
        }
        
        // draw title:
        if let title = params.siteInfo?.title {
            var titleAttrs = [String: AnyObject]()
            titleAttrs[NSForegroundColorAttributeName] = params.previewImage == nil ? UIColor.blackColor() : UIColor.whiteColor()
            titleAttrs[NSFontAttributeName] = TextCardItemView.boldFont.fontWithSize(titleSize)
            titleAttrs[NSParagraphStyleAttributeName] = NSAttributedString.paragraphStyleWithTextAlignment(drawSiteName ? .Left : .Center)
            let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
            let maxSize = CGSizeMake(bounds.size.width - padding * 2, bounds.size.height - padding * 3 - siteSize)
            let size = titleStr.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin, context: nil)
            let backdropHeight = drawSiteName ? size.height + padding * 2 : bounds.size.height
            if params.previewImage != nil {
                UIColor(white: 0.1, alpha: 0.5).setFill()
                UIBezierPath(rect: CGRectMake(0, bounds.size.height - backdropHeight, bounds.size.width, backdropHeight)).fill()
            }
            if drawSiteName {
                let y = bounds.size.height - padding - size.height
                titleStr.drawInRect(CGRectMake(padding, y, bounds.size.width - padding * 2, bounds.size.height))
            } else {
                titleStr.drawVerticallyCenteredInRect(CGRectInset(bounds, padding, padding))
            }
        }
    }
}
