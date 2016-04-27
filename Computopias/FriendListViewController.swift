//
//  FriendListViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/9/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class FriendListViewController: UITableViewController {
    let source = FriendListDataSource()
    var _sub: Subscription?
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Friends"
        _sub = source.onUpdate.subscribe({ [weak self] (let _) in
            self?._update()
        })
        _update()
    }
    func _update() {
        var sections = [Section]()
        if source._newFollowers.count > 0 {
            let sec = NewFollowersSection()
            sec.models = source._newFollowers
            sections.append(sec)
        }
        let friendsSec = BasicTextSection()
        sections.append(friendsSec)
        friendsSec.title = "Friends"
        for id in source._friendIDs {
            let unfollow: () -> () = {
                Data.setFollowing(id, following: false, type: .User)
            }
            let showFriendProfile = {
                (UIApplication.sharedApplication().delegate as! AppDelegate).navigateToRoute(Route.Profile(id: id))
            }
            friendsSec.rows.append(BasicTextSection.Row(title: "", action: showFriendProfile, dim: false, center: false, titleFirebase: Data.firebase.childByAppendingPath("users").childByAppendingPath(id).childByAppendingPath("name"), deleteAction: unfollow))
        }
        if source._searchingContactsInProgress {
            friendsSec.rows.append(BasicTextSection.Row(title: "⏳ Searching for friends", action: nil, dim: true, center: true, titleFirebase: nil, deleteAction: nil))
        } else if Data.shouldPromptToDoContactSync() {
            let sync: () -> () = {
                [weak self] in
                self?.source._doContactsSync()
            }
            friendsSec.rows.append(BasicTextSection.Row(title: "👫 Search for friends in contacts", action: sync, dim: false, center: true, titleFirebase: nil, deleteAction: nil))
        }
        if friendsSec.rows.count == 0 {
            friendsSec.rows.append(BasicTextSection.Row(title: "No friends 😕", action: nil, dim: true, center: true, titleFirebase: nil, deleteAction: nil))
        }
        self.sections = sections
    }
    @IBAction func addFriends() {
        source.addFriends()
    }
    // MARK: Sections
    class Section {
        init() {
            
        }
        var title: String?
        var models = [AnyObject]()
        func createCell(model: AnyObject, table: UITableView) -> UITableViewCell! {
            return nil
        }
        func clickedCell(model: AnyObject, parent: FriendListViewController) {
            
        }
        func canDeleteModel(model: AnyObject) -> Bool {
            return false
        }
        func deleteModel(model: AnyObject) {
            
        }
    }
    class NewFollowersSection: Section {
        override init() {
            super.init()
            title = "New followers"
        }
        override func createCell(model: AnyObject, table: UITableView) -> UITableViewCell! {
            let cell = table.dequeueReusableCellWithIdentifier("NewFollowerCell") as! NewFollowerCell
            cell.follower = model as? [String: AnyObject]
            return cell
        }
    }
    class BasicTextSection: Section {
        struct Row {
            var title: String
            var action: (() -> ())?
            var dim: Bool
            var center: Bool
            var titleFirebase: Firebase?
            var deleteAction: (() -> ())? = nil
        }
        var rows = [Row]() {
            didSet {
                models = Array(0..<rows.count)
            }
        }
        override func createCell(model: AnyObject, table: UITableView) -> UITableViewCell! {
            let cell = table.dequeueReusableCellWithIdentifier("BasicTextCell") as! BasicTextCell
            let row = rows[model as! Int]
            cell.textLabel!.text = row.title
            cell.textLabel?.alpha = row.dim ? 0.5 : 1
            cell.selectionStyle = row.action == nil ? .None : .Default
            cell.textLabel?.textAlignment = row.center ? .Center : .Left
            cell.titleFirebase = row.titleFirebase
            return cell
        }
        override func clickedCell(model: AnyObject, parent: FriendListViewController) {
            let row = rows[model as! Int]
            row.action?()
        }
        override func canDeleteModel(model: AnyObject) -> Bool {
            let row = rows[model as! Int]
            return row.deleteAction != nil
        }
        override func deleteModel(model: AnyObject) {
            let row = rows[model as! Int]
            row.deleteAction!()
        }
    }
    var sections = [Section]() {
        didSet {
            tableView.reloadData()
        }
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].models.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let model = section.models[indexPath.row]
        return section.createCell(model, table: tableView)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = sections[indexPath.section]
        let model = section.models[indexPath.row]
        section.clickedCell(model, parent: self)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let section = sections[indexPath.section]
        let model = section.models[indexPath.row]
        return section.canDeleteModel(model)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let section = sections[indexPath.section]
        let model = section.models[indexPath.row]
        
        switch editingStyle {
        case .Delete:
            section.deleteModel(model)
        default: ()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

class BasicTextCell: UITableViewCell {
    var titleFirebase: Firebase? {
        didSet {
            _titleSub = nil
            if let t = titleFirebase {
                textLabel!.text = " "
                _titleSub = t.pusher.subscribe({ [weak self] (let val) in
                    self?.textLabel?.text = val as? String
                })
            }
        }
    }
    var _titleSub: Subscription?
}

class NewFollowerCell: UITableViewCell {
    @IBOutlet var label: UILabel!
    @IBAction func dismiss() {
        if let uid = follower?["uid"] as? String {
            Data.firebase.childByAppendingPath("new_followers").childByAppendingPath(Data.getUID()!).childByAppendingPath(uid).setValue(nil)
        }
    }
    @IBAction func follow() {
        if let uid = follower?["uid"] as? String {
            Data.setFollowing(uid, following: true, type: .User)
            Data.firebase.childByAppendingPath("new_followers").childByAppendingPath(Data.getUID()!).childByAppendingPath(uid).setValue(nil)
        }
    }
    var follower: [String: AnyObject]? {
        didSet {
            label.text = follower?["name"] as? String
        }
    }
}
