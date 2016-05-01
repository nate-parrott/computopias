//
//  ImageSearchViewController.swift
//  Backgrounder
//
//  Created by Nate Parrott on 6/17/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

import UIKit

class DownloadIndicatorView: UIView {
    var imageView: UIImageView
    override init(frame: CGRect) {
        imageView = UIImageView(frame: frame)
        super.init(frame: frame)
        
        backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        
        let buttonHeight: CGFloat = 40
        addSubview(imageView)
        imageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-buttonHeight)
        imageView.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        let button = UIButton(type: UIButtonType.Custom) as UIButton
        button.setTitle(NSLocalizedString("Cancel", comment: ""), forState: UIControlState.Normal)
        addSubview(button)
        button.frame = CGRectMake(0, self.bounds.size.height-buttonHeight, self.bounds.size.width, buttonHeight)
        button.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleTopMargin]
        button.addTarget(self, action: #selector(DownloadIndicatorView.cancel), forControlEvents: UIControlEvents.TouchUpInside)
        
        let loader = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        addSubview(loader)
        loader.center = CGPointMake(loader.frame.size.width/2.0 + 10, loader.frame.size.height/2.0 + 10)
        loader.autoresizingMask = [UIViewAutoresizing.FlexibleBottomMargin, UIViewAutoresizing.FlexibleRightMargin]
        loader.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onCancel: (()->())?
    func cancel() {
        if let c = onCancel {
            c()
        }
    }
}

class ImageSearchViewController: UIViewController, AFImageSearchResultsViewControllerDelegate, UISearchBarDelegate {
    var searchbar: UISearchBar?
    var searchResults: AFImageSearchResultsViewController?
    override func viewDidLoad()  {
        super.viewDidLoad()
        
        let s = UISearchBar(frame: CGRectMake(0, 0, 250, 30))
        navigationItem.titleView = s
        s.placeholder = NSLocalizedString("Bing Image Search…", comment: "")
        s.delegate = self
        searchbar = s
        
        let results = AFImageSearchResultsViewController()
        addChildViewController(results)
        view.addSubview(results.view)
        results.view.frame = view.bounds
        results.view.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth];
        results.delegate = self
        searchResults = results
        
        results.collectionView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(ImageSearchViewController.cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: UIView(frame: CGRectMake(0, 0, 30, 10)))
        
        downloadIndicator = DownloadIndicatorView(frame: view.bounds)
        view.addSubview(downloadIndicator!)
        downloadIndicator!.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        downloadIndicator!.onCancel = {[weak self] in
            self!.downloadTask!.cancel()
            self!.downloadTask = nil
        }
        downloadTask = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        searchbar!.becomeFirstResponder()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) { // called when keyboard search button pressed
        searchResults!.query = searchBar.text
        searchBar.resignFirstResponder()
    }
    
    func cancel(sender: UIBarButtonItem) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageSearchResultsViewController(resultsController: AFImageSearchResultsViewController!, didPickImageAtURL imageURL: NSURL!, sourceImageView imageView: UIImageView!) {
        downloadIndicator!.imageView.image = imageView.image
        
        downloadTask = NSURLSession.sharedSession().dataTaskWithURL(imageURL, completionHandler: {
            (data: NSData?, response: NSURLResponse?, error: NSError?) in
            dispatch_async(dispatch_get_main_queue(), {
                self.networkActivityCount -= 1
                if let d = data, let image = UIImage(data: d) {
                    if let p = self.onImagePicked {
                        p(image)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                } else if error != nil {
                    let alertController = UIAlertController(title: nil, message: NSLocalizedString("That image couldn't be downloaded.", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment: ""), style: .Cancel, handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                self.downloadTask = nil
            })
        })
        networkActivityCount += 1
        downloadTask!.resume()
    }
    
    var onImagePicked: ((UIImage) -> ())?
    
    var downloadIndicator: DownloadIndicatorView?
    var downloadTask: NSURLSessionDataTask? {
        didSet {
            downloadIndicator!.hidden = (downloadTask==nil)
        }
    }
    
    func imageSearchResultsViewControllerDidStartLoading(resultsController: AFImageSearchResultsViewController!) {
        networkActivityCount += 1
    }
    
    func imageSearchResultsViewControllerDidFinishLoading(resultsController: AFImageSearchResultsViewController!) {
        networkActivityCount -= 1
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        networkActivityCount = 0
    }
    
    var networkActivityCount: Int = 0 {
        willSet(newVal) {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if networkActivityCount == 0 && newVal > 0 {
                appDelegate.incrementNetworkActivityCounter(1)
            } else if newVal == 0 && networkActivityCount > 0 {
                appDelegate.incrementNetworkActivityCounter(-1)
            }
        }
    }
}
