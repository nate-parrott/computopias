//
//  NavViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NavViewController: UIViewController, UITextFieldDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        currentQuery = ""
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if Data.getName() == nil {
            presentViewController(storyboard!.instantiateViewControllerWithIdentifier("Profile"), animated: true, completion: nil)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    var currentQuery: String = "" {
        didSet {
            queryField.text = currentQuery
            if currentQuery == "" {
                let list = storyboard!.instantiateViewControllerWithIdentifier("HashtagList") as! HashtagListViewController
                list.onPickQuery = {
                    [weak self] (query) in
                    self?.currentQuery = query
                }
                childVC = list
            } else {
                let feed = storyboard!.instantiateViewControllerWithIdentifier("CardFeed") as! CardFeedViewController
                feed.hashtag = currentQuery
                childVC = feed
            }
        }
    }
    
    @IBOutlet var queryField: UITextField!
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        currentQuery = queryField.text ?? ""
        textField.resignFirstResponder()
        return true
    }
    
    @IBOutlet var childContainer: UIView!
    
    var childVC: UIViewController? {
        willSet(vc) {
            if let old = childVC {
                old.view.removeFromSuperview()
                old.removeFromParentViewController()
            }
            if let newVC = vc {
                addChildViewController(newVC)
                childContainer.addSubview(newVC.view)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let v = childVC?.view {
            v.frame = childContainer.bounds
        }
    }
}
