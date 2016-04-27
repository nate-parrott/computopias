//
//  GroupsListViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/17/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class GroupsListViewController: NavigableViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(GroupCell.self, forCellReuseIdentifier: "GroupCell")
        tableView.rowHeight = round(CardView.CardSize.height * GroupCell.cardScale) + GroupCell.padding
        tableView.separatorStyle = .None
        
        searchField.frame = CGRectMake(0, 0, 100, 40)
        tableView.tableHeaderView = searchField
        searchField.textAlignment = .Center
        searchField.placeholder = "  Search…"
        searchField.font = UIFont.systemFontOfSize(16) // UIFont.italicSystemFontOfSize(16)
        searchField.autocorrectionType = .No
        searchField.autocapitalizationType = .None
        searchField.delegate = self
        searchOverlay.hidden = true
        view.addSubview(searchOverlay)
        searchOverlay.addSubview(searchOverlayDismissButton)
        searchOverlayDismissButton.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        searchOverlayDismissButton.addTarget(self, action: #selector(GroupsListViewController.endSearch), forControlEvents: .TouchUpInside)
        searchOverlay.addSubview(searchVC.view)
        searchVC.parent = self
        
        actionBarContent = nil
    }
    // MARK: Data
    override func startUpdating() {
        source = ActivityFeedSource()
        _modelsSub = source?.groupsListModels.subscribe({ [weak self] (let models) in
            if self?.source?.fullyLoaded ?? false {
                self?.models = models
            }
        })
        if source?.fullyLoaded ?? false {
            models = source!.groupsListModels.val
        }
        _notificationCounterSub = NotificationsSource.Shared.unreadCount.subscribe({ [weak self] (let count) in
            self?._updateNotificationsButton()
        })
        _updateNotificationsButton()
        if Data.shouldPromptToDoContactSync() {
            actionBarContent = ActionBarContent(title: "Follow friends from your contacts", action: { [weak self] in
                self?.syncContacts()
                }, onDismiss: { 
                    Data.noThanksNoContactSyncForMe()
            })
        }
        super.startUpdating()
    }
    override func stopUpdating() {
        source = nil
        _notificationCounterSub = nil
        super.stopUpdating()
    }
    var source: ActivityFeedSource?
    var models: [ActivityFeedSource.Model] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var _modelsSub: Subscription?
    var _notificationCounterSub: Subscription?
    
    // MARK: Search
    let searchField = UITextField()
    func searchChanged(text: String) {
        searchVC.query = text
        searchOverlayVisible = (text != "")
        view.setNeedsLayout()
    }
    let searchOverlay = UIView()
    let searchVC = SearchViewController()
    let searchOverlayDismissButton = UIButton()
    var searchOverlayVisible = false {
        didSet {
            searchOverlay.hidden = !searchOverlayVisible
        }
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).stringByReplacingCharactersInRange(range, withString: string).sanitizedForFirebase.lowercaseString
        searchChanged(text)
        return true
    }
    func endSearch() {
        searchField.resignFirstResponder()
    }
    func textFieldDidBeginEditing(textField: UITextField) {
        if searchVC.query != "" { searchOverlayVisible = true }
    }
    func textFieldDidEndEditing(textField: UITextField) {
        searchOverlayVisible = false
    }
    // MARK: Notifications
    @IBOutlet var notificationIcon: UIBarButtonItem!
    func _updateNotificationsButton() {
        let unreadCount = NotificationsSource.Shared.unreadCount.val
        notificationIcon.image = GroupsListViewController.RenderNotificationsIconWithCount(unreadCount)
        // notificationsButton.setTitle("\(unreadCount)", forState: .Normal)
    }
    static func RenderNotificationsIconWithCount(count: Int) -> UIImage {
        if (count == 0) {
            return UIImage(named: "NotificationsEmpty")!
        } else {
            let bg = UIImage(named: "NotificationsFull")!
            let text = NSAttributedString(string: "\(count)", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(10), NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: NSAttributedString.paragraphStyleWithTextAlignment(.Center)])
            UIGraphicsBeginImageContextWithOptions(bg.size, false, UIScreen.mainScreen().scale)
            bg.drawAtPoint(CGPointZero)
            text.drawVerticallyCenteredInRect(CGRectMake(0, 0, bg.size.width, bg.size.height))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image.imageWithRenderingMode(.AlwaysOriginal)
        }
    }
    // MARK: Actions
    @IBAction func showFriends() {
        NPSoftModalPresentationController.presentViewController(UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Friends"))
    }
    @IBAction func createGroup() {
        NPSoftModalPresentationController.presentViewController(UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("GroupNamePicker"))
    }
    @IBAction func showNotifications() {
        navigationController?.pushViewController(storyboard!.instantiateViewControllerWithIdentifier("Notifications"), animated: true)
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
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchField.resignFirstResponder()
    }
    // MARK: Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let y = view.convertPoint(CGPointZero, fromView: searchField).y + searchField.frame.size.height
        searchOverlay.frame = CGRectMake(0, y, view.bounds.size.width, view.bounds.size.height - y)
        searchOverlayDismissButton.frame = searchOverlay.bounds
        let w: CGFloat = 260
        let x = (searchOverlay.frame.size.width - w) / 2
        searchVC.view.frame = CGRectMake(x, 10, w, 120)
    }
    // MARK: ActionBar
    @IBAction func pressedActionBar() {
        if let a = actionBarContent?.action {
            a()
        }
        actionBarContent = nil
    }
    @IBAction func dismissActionBar() {
        if let o = actionBarContent?.onDismiss {
            o()
        }
        actionBarContent = nil
    }
    @IBOutlet var actionBar: UIView!
    @IBOutlet var actionBarTitle: UILabel!
    struct ActionBarContent {
        var title: String
        var action: (() -> ())?
        var onDismiss: (() -> ())?
    }
    var actionBarContent: ActionBarContent? {
        didSet {
            if let a = actionBarContent {
                actionBar.hidden = false
                actionBarTitle.text = a.title
            } else {
                actionBar.hidden = true
            }
        }
    }
    // MARK: Sync contacts
    func syncContacts() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Friends") as! UINavigationController
        let friendsVC = vc.viewControllers.first! as! FriendListViewController
        NPSoftModalPresentationController.presentViewController(vc)
        delay(1, closure: {
            friendsVC.source._doContactsSync()
        })
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
