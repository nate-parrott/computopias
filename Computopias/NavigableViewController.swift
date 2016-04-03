//
//  NavigableViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NavigableViewController: UIViewController, UISearchBarDelegate, UIGestureRecognizerDelegate {
    // MARK: Routing
    class func FromRoute(route: Route) -> NavigableViewController! {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: NavigableViewController!
        switch route {
        case .Card(hashtag: let hashtag, id: let id):
            if hashtag == "profiles" {
                vc = storyboard.instantiateViewControllerWithIdentifier("UserCardViewController") as! UserCardViewController
                (vc as! UserCardViewController).userID = id
            } else {
                vc = storyboard.instantiateViewControllerWithIdentifier("CardFeedViewController") as! CardFeedViewController
            }
            vc!.route = route
            (vc as! CardFeedViewController).rows = [CardFeedViewController.RowModel.Card(id: id, hashtag: hashtag)]
        case .Hashtag(name: let hashtag):
            vc = storyboard.instantiateViewControllerWithIdentifier("HashtagViewController") as! HashtagViewController
            (vc as! HashtagViewController).hashtag = hashtag
        case .HashtagsList:
            vc = storyboard.instantiateViewControllerWithIdentifier("ActivityFeed") as! ActivityFeedViewController
        case .ProfilesList:
            vc = storyboard.instantiateViewControllerWithIdentifier("FriendFeedViewController") as! FriendFeedViewController
        default:
            vc = storyboard.instantiateViewControllerWithIdentifier("NavigableViewController") as! NavigableViewController
        }
        vc?.route = route
        return vc
    }
    
    var route: Route!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isHome {
            searchBar.text = route.string
        }
        searchBar.placeholder = "Search…"
        navigationItem.titleView = searchBar
        searchBar.frame = CGRectMake(0, 0, 200, searchBar.bounds.size.height)
        searchBar.delegate = self
        searchBar.setImage(UIImage(), forSearchBarIcon: .Clear, state: .Normal)
        searchBar.barTintColor = UIColor.clearColor()
        searchBar.backgroundColor = UIColor.clearColor()
        searchBar.searchBarStyle = .Minimal
        searchBar.autocapitalizationType = .None
        searchBar.autocorrectionType = .No
        searchBar.backgroundImage = UIImage()
        
        if !isHome {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NavHome"), style: .Plain, target: self, action: #selector(NavigableViewController.home))
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NavigableViewController._onLoggedIn), name: Data.LoginDidCompleteNotification, object: nil)
    }
    
    var visible = false {
        didSet {
            _updating = visible && Data.getUID() != nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _setupBarsAnimated(animated)
        visible = true
        if navigationController?.viewControllers.count > 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "NavBack"), style: .Plain, target: self, action: #selector(NavigableViewController.back))
            navigationController!.interactivePopGestureRecognizer!.delegate = self
        }
    }
    
    func back() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        visible = false
    }
    
    // Mark: Data observing
    
    func _onLoggedIn() {
        _updating = false
        _updating = visible && Data.getUID() != nil
    }
    
    var _updating = false {
        didSet(oldVal) {
            if oldVal != _updating {
                if _updating {
                    startUpdating()
                } else {
                    stopUpdating()
                }
            }
        }
    }
    
    func startUpdating() {
        
    }
    
    func stopUpdating() {
        
    }
    
    // MARK: Search bar/nav
    
    func _setupBarsAnimated(animated: Bool) {
        /*if self === navigationController?.viewControllers.first {
            let dummy = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            navigationItem.leftBarButtonItem = dummy
        }*/
                
        let hasToolbar = getTabs() != nil
        if let tabs = getTabs() {
            let flex1 = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let flex2 = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            _tabBarButtonItems = tabs.map({ UIBarButtonItem(title: $0.0, style: .Plain, target: self, action: #selector(NavigableViewController.switchTab)) })
            _tabRoutes = tabs.map({ $0.1 })
            for (item, route) in zip(_tabBarButtonItems!, _tabRoutes!) {
                item.tintColor = (route.string == self.route.string) ? nil : UIColor.grayColor()
            }
            toolbarItems = [flex1] + _tabBarButtonItems! + [flex2]
        }
        navigationController?.setToolbarHidden(!hasToolbar, animated: animated)
    }
    
    let searchBar = UISearchBar()
    func home(sender: AnyObject) {
        navigate(Route.HashtagsList)
    }
    func navigate(route: Route) -> NavigableViewController {
        let vc =  NavigableViewController.FromRoute(route)
        navigationController!.pushViewController(vc, animated: true)
        return vc
    }
    func navigateInPlace(route: Route) -> NavigableViewController {
        let vc =  NavigableViewController.FromRoute(route)
        let nav = navigationController!
        var vcs = nav.viewControllers
        vcs[vcs.count-1] = vc
        nav.viewControllers = vcs
        return vc
    }
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let text = searchBar.text where text != "" {
            navigate(Route.fromString(text) ?? Route.Nothing)
        }
        searchBar.resignFirstResponder()
    }
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.text = isHome ? "" : route.string
        searchBar.setShowsCancelButton(false, animated: true)
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    var isHome: Bool {
        get {
            return false
        }
    }
    
    // MARK: Tabs
    var _tabBarButtonItems: [UIBarButtonItem]?
    var _tabRoutes: [Route]?
    func switchTab(sender: UIBarButtonItem) {
        navigateInPlace(_tabRoutes![_tabBarButtonItems!.indexOf(sender)!])
    }
    
    func getTabs() -> [(String, Route)]? {
        return nil
    }
    
    class func homeTabs() -> [(String, Route)] {
        return [("New", Route.HashtagsList), ("Friends", Route.ProfilesList)]
    }
    
    // MARK: Memory warnings
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        let maxPages = 5
        if let nav = navigationController where nav.viewControllers.first === self && nav.viewControllers.count > maxPages {
            var vcs = nav.viewControllers
            while vcs.count > maxPages {
                vcs.removeAtIndex(0)
            }
            nav.viewControllers = vcs
        }
    }
    
    // MARK: Convenience
    func showAlert(text: String) {
        let a = UIAlertController(title: nil, message: text, preferredStyle: .Alert)
        a.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        presentViewController(a, animated: true, completion: nil)
    }
    
    // MARK: Layout
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
