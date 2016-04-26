//
//  SearchViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/26/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class SearchViewController: UITableViewController {
    // MARK: Table
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.layer.cornerRadius = CardView.rounding
        view.clipsToBounds = true
    }
    struct Model {
        var title: String
        var route: Route?
    }
    class Section {
        var title: String?
        var models = [Model]()
    }
    var sections = [Section]() {
        didSet {
            tableView.reloadData()
        }
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].models.count
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        let model = sections[indexPath.section].models[indexPath.row]
        cell.textLabel?.text = model.title
        cell.accessoryType = .DisclosureIndicator
        cell.textLabel?.font = UIFont.systemFontOfSize(16)
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let route = sections[indexPath.section].models[indexPath.row].route {
            parent.navigate(route)
        }
    }
    // MARK: API
    var parent: NavigableViewController!
    // MARK: Loading data
    var query: String = "" {
        didSet {
            _currentHashtagIsTaken = nil
            _uidForPhoneNumber = nil
            _lookedForUserWithPhoneNumber = nil
            let q = query
            if q.normalizedPhone.utf16.count >= 10 {
                Data.findUserByPhone(q.normalizedPhone, callback: { (let snapshotOpt) in
                    if q == self.query {
                        self._uidForPhoneNumber = snapshotOpt?.key
                        self._lookedForUserWithPhoneNumber = true
                        self._updateContent()
                    }
                })
            } else {
                _uidForPhoneNumber = nil
            }
            if q != "" {
                Data.firebase.childByAppendingPath("all_hashtags").childByAppendingPath(q.lowercaseString.sanitizedForFirebase).get({ (let objOpt) in
                    let hashtagTaken = (objOpt as? NSNull) != nil
                    if q == self.query {
                        self._currentHashtagIsTaken = hashtagTaken
                        self._updateContent()
                    }
                })
            }
            _updateContent()
        }
    }
    var _currentHashtagIsTaken: Bool?
    var _uidForPhoneNumber: String?
    var _lookedForUserWithPhoneNumber: Bool?
    func _updateContent() {
        var models = [Model]()
        if let taken = _currentHashtagIsTaken {
            let hashtag = query.lowercaseString.sanitizedForFirebase
            if taken {
                models.append(Model(title: "Go to group #\(hashtag)", route: Route.Hashtag(name: hashtag)))
            } else {
                models.append(Model(title: "Create group #\(hashtag)", route: Route.Hashtag(name: hashtag))) // TODO: allow creation
            }
        }
        if _lookedForUserWithPhoneNumber ?? false {
            let phone = query.normalizedPhone
            if let uid = _uidForPhoneNumber {
                models.append(Model(title: "User \(phone)", route: Route.Profile(id: uid)))
            } else {
                models.append(Model(title: "No user with phone \(phone)", route: nil))
            }
        }
        let s = Section()
        s.models = models
        sections = [s]
    }
}
