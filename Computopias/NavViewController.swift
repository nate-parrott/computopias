//
//  NavViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NavViewController: UIViewController, UITextFieldDelegate {
    static var shared: NavViewController! {
        get {
            return UIApplication.sharedApplication().delegate?.window!!.rootViewController! as! NavViewController
        }
    }
    
    func navigate(address: String) {
        backStack.append(address)
        currentQuery = address
    }
    var backStack = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigate("")
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
    
    private var currentQuery: String = "" {
        didSet {
            let route = Route.fromString(currentQuery)
            queryField.text = route.string
            plus.hidden = true
            
            switch route {
            case .Hashtag(name: let hashtag):
                let feed = storyboard!.instantiateViewControllerWithIdentifier("CardFeed") as! CardFeedViewController
                feed.hashtag = hashtag.sanitizedForFirebase
                childVC = feed
                plus.hidden = false
            case .Card(hashtag: let hashtag, id: let id):
                let vc = storyboard!.instantiateViewControllerWithIdentifier("SingleCard") as! SingleCardViewController
                vc.hashtag = hashtag
                vc.cardFirebase = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id)
                childVC = vc
            case .Profile(name: let _):
                () // TODO
            case .Home:
                let list = storyboard!.instantiateViewControllerWithIdentifier("HashtagList") as! HashtagListViewController
                list.onPickQuery = {
                    [weak self] (query) in
                    self?.navigate(query)
                }
                childVC = list
            default: ()
            }
            back.hidden = backStack.count <= 1
        }
    }
    
    @IBOutlet var queryField: UITextField!
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        navigate(queryField.text ?? "")
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
    
    @IBOutlet var back: UIButton!
    @IBOutlet var plus: UIButton!
    @IBAction func goBack() {
        backStack.removeLast()
        currentQuery = backStack.last!
    }
    @IBAction func addPost() {
        if let feed = childVC as? CardFeedViewController {
            feed.addPost()
        }
    }
}
