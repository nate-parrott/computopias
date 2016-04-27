//
//  NotificationsViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/25/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class NotificationsViewController: NavigableViewController, UITableViewDelegate, UITableViewDataSource {
    override func viewDidLoad() {
        super.viewDidLoad()
        _subscription = NotificationsSource.Shared.notificationDicts.subscribe({ [weak self] (dicts) in
            self?._notificationDicts = dicts
        })
        _notificationDicts = NotificationsSource.Shared.notificationDicts.val
        table.estimatedRowHeight = 44
        table.rowHeight = UITableViewAutomaticDimension
    }
    var _subscription: Subscription?
    var _notificationDicts: [[String: AnyObject]] = [] {
        didSet {
            table.reloadData()
        }
    }
    @IBOutlet var table: UITableView!
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if _notificationDicts.count == 0 {
            return 1
        } else {
            return _notificationDicts.count
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if _notificationDicts.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("EmptyCell")!
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
            cell.textLabel?.text = _notificationDicts[indexPath.row]["text"] as? String
            return cell
        }
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if _notificationDicts.count > 0 {
            if let urlString = _notificationDicts[indexPath.row]["url"] as? String,
                let url = NSURL(string: urlString),
                let route = Route.fromURL(url) {
                navigate(route)
            }
        }
    }
    override var underlayNavBar: Bool {
        get {
            return true
        }
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let idx = table.indexPathForSelectedRow {
            table.deselectRowAtIndexPath(idx, animated: animated)
        }
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NotificationsSource.Shared.markAllAsRead()
    }
}
