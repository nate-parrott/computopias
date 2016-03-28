//
//  NavigableViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NavigableViewController: UIViewController {
    class func FromRoute(route: Route) -> NavigableViewController! {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: NavigableViewController!
        switch route {
        case .Card(hashtag: let hashtag, id: let id):
            vc = storyboard.instantiateViewControllerWithIdentifier("CardFeedViewController") as! CardFeedViewController
            (vc as! CardFeedViewController).rows = [CardFeedViewController.RowModel.Card(id: id, hashtag: hashtag)]
        case .Hashtag(name: let hashtag):
            vc = storyboard.instantiateViewControllerWithIdentifier("HashtagViewController") as! HashtagViewController
            (vc as! HashtagViewController).hashtag = hashtag
        case .HashtagsList:
            vc = storyboard.instantiateViewControllerWithIdentifier("HashtagListViewController") as! HashtagListViewController
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
        navigationController!.popViewControllerAnimated(false)
        navigationController!.pushViewController(vc, animated: false)
        return vc
    }
}
