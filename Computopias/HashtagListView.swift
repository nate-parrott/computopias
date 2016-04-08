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
            tableView.tableHeaderView = searchBar
        }
    }
    
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
    
    // MARK: TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hashtags.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.textLabel?.text = "#" + hashtags[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
