//
//  HashtagListView.swift
//  Computopias
//
//  Created by Nate Parrott on 4/7/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class HashtagListView: UIView, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToSuperview(newWindow)
        if !_setup {
            _setup = true
            
            tintColor = UIColor.whiteColor()
            
            clipsToBounds = true
            layer.cornerRadius = CardView.rounding
            
            addSubview(background)
            background.image = Appearance.gradientForHashtag("HashtagListView", cardID: nil) // UIImage(named: "graydient")
            
            addSubview(tableView)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
            tableView.backgroundColor = UIColor.clearColor()
            tableView.separatorStyle = .None
            
            searchBar.frame = CGRectMake(0, 0, 10, 44)
            searchBar.searchBarStyle = .Minimal
            searchBar.delegate = self
            searchBar.autocorrectionType = .No
            searchBar.autocapitalizationType = .None
            tableView.tableHeaderView = searchBar
            
            _sub = Data.userInfoFirebase().childByAppendingPath("following_hashtags").pusher.subscribe({ [weak self] (let data) in
                if let hashtags = (data as? [String: AnyObject]) {
                    self?.hashtags = Array(hashtags.keys)
                } else {
                    self?.hashtags = []
                }
            })
        }
    }
    
    var _sub: Subscription?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
        background.frame = bounds
    }
    
    var _setup = false
    let tableView = UITableView(frame: CGRectZero, style: .Plain)
    let background = UIImageView()
    let searchBar = UISearchBar()
    
    var hashtags = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    var onNavigate: (Route -> ())!
    
    // MARK: Searchbar
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let text = searchBar.text where text != "" && text.componentsSeparatedByString(" ").count == 1 {
            delay(1, closure: { 
                searchBar.text = ""
            })
            var t = text
            if t.characters.first == "#".characters.first {
                t = t[1..<t.utf16.count]
            }
            onNavigate(Route.Hashtag(name: t))
        }
    }
    
    // MARK: TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.text = "#" + hashtags[indexPath.row]
        cell.textLabel?.textColor = UIColor(white: 0.1, alpha: 0.8)
        cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16)
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        onNavigate(Route.Hashtag(name: hashtags[indexPath.row]))
    }
}
