//
//  GroupsListViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/17/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class GroupsListViewController: NavigableViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(GroupCell.self, forCellReuseIdentifier: "GroupCell")
        tableView.rowHeight = round(CardView.CardSize.height * GroupCell.cardScale) + GroupCell.padding
        // tableView.separatorColor = UIColor(patternImage: UIImage())
        tableView.separatorStyle = .None
    }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("GroupCell")!
        (cell as! GroupCell).model = models[indexPath.row]
        // cell.textLabel!.text = m.title
        // cell.detailTextLabel!.text = m.subtitle
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        navigate(models[indexPath.row].route)
    }
}

class GroupCell: UITableViewCell {
    static let cardScale: CGFloat = 0.3
    static let padding: CGFloat = 12
    var model: ActivityFeedSource.Model? {
        didSet {
            if !_setupYet {
                _setup()
            }
            if let m = model {
                let text = NSAttributedString(string: m.title + "\n", attributes: [NSFontAttributeName: NSAttributedString.defaultBoldFontAtSize(19)]) + NSAttributedString.smallText(m.subtitle)
                label.attributedString = text
                _cardID = m.cardID
            }
        }
    }
    var _cardID: String? {
        didSet {
            if let id = _cardID {
                let cardFirebase = Data.firebase.childByAppendingPath("cards").childByAppendingPath(id)
                cardView.cardFirebase = cardFirebase
                cardFirebase.observeSingleEventOfType(.Value, withBlock: { [weak self] (let snapshot: FDataSnapshot!) in
                    if let s = self where s._cardID == id,
                       let json = snapshot.value as? [String: AnyObject]
                    {
                        s.cardView.presentJson(json)
                    }
                })
            }
        }
    }
    let cardView = CardView()
    let label = ASLabelNode()
    var _setupYet = false
    func _setup() {
        _setupYet = true
        cardView.bounds = CGRectMake(0, 0, CardView.CardSize.width, CardView.CardSize.height)
        contentView.addSubnode(cardView)
        addSubnode(label)
        cardView.userInteractionEnabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let cardScale = GroupCell.cardScale
        let cardSize = CardView.CardSize * cardScale
        let padding = GroupCell.padding
        cardView.transform = CATransform3DMakeScale(cardScale, cardScale, 1)
        cardView.position = CGPointMake(cardSize.width/2 + padding, bounds.size.height / 2)
        label.frame = CGRectMake(cardSize.width + padding * 2, padding/2, bounds.size.width - cardSize.width - padding * 3, bounds.size.height - padding)
        
    }
}
