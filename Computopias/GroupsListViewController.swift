//
//  GroupsListViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/17/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class GroupsListViewController: NavigableViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Data
    override func startUpdating() {
        source = ActivityFeedSource()
        _modelsSub = source?.groupsListModels.subscribe({ [weak self] (let models) in
            self?.models = models
        })
        models = source!.groupsListModels.val
        super.startUpdating()
    }
    override func stopUpdating() {
        source = nil
        super.stopUpdating()
    }
    var source: ActivityFeedSource?
    var models: [ActivityFeedSource.Model] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var _modelsSub: Subscription?
    // MARK: Actions
    @IBAction func showFriends() {
        NPSoftModalPresentationController.presentViewController(UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Friends"))
    }
    @IBAction func createGroup() {
        NPSoftModalPresentationController.presentViewController(UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("GroupNamePicker"))
    }
    // MARK: Table
    @IBOutlet var tableView: UITableView!
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        let m = models[indexPath.row]
        cell.textLabel!.text = m.title
        cell.detailTextLabel!.text = m.subtitle
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        navigate(models[indexPath.row].route)
    }
}
