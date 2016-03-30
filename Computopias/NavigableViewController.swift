//
//  NavigableViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NavigableViewController: UIViewController, UISearchBarDelegate {
    class func FromRoute(route: Route) -> NavigableViewController! {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: NavigableViewController!
        switch route {
        case .Card(hashtag: let hashtag, id: let id):
            vc = storyboard.instantiateViewControllerWithIdentifier("CardFeedViewController") as! CardFeedViewController
            vc!.route = route
            (vc as! CardFeedViewController).rows = [CardFeedViewController.RowModel.Card(id: id, hashtag: hashtag)]
        case .Hashtag(name: let hashtag):
            vc = storyboard.instantiateViewControllerWithIdentifier("HashtagViewController") as! HashtagViewController
            (vc as! HashtagViewController).hashtag = hashtag
        case .HashtagsList:
            vc = storyboard.instantiateViewControllerWithIdentifier("HashtagListViewController") as! HashtagListViewController
        case .ProfilesList:
            vc = storyboard.instantiateViewControllerWithIdentifier("FriendFeedViewController") as! FriendFeedViewController
        default:
            vc = storyboard.instantiateViewControllerWithIdentifier("NavigableViewController") as! NavigableViewController
        }
        vc?.route = route
        return vc
    }
    
    var route: Route!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.text = route.string
        navigationItem.titleView = searchBar
        searchBar.frame = CGRectMake(0, 0, searchBar.bounds.size.height, 200)
        searchBar.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Home", style: .Plain, target: self, action: #selector(NavigableViewController.home))
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
            navigate(Route.fromString(text))
        }
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
}
