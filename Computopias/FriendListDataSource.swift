//
//  FriendListDataSource.swift
//  Computopias
//
//  Created by Nate Parrott on 4/9/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation
import Firebase

class FriendListDataSource {
    var _newFollowersSub: Subscription?
    var _friendsListSub: Subscription?
    
    init() {
        
        if Data.getUID() != nil {
            _friendsListSub = Data.friendFeed().subscribe({ [weak self] (let friendIDs) in
                self?._friendIDs = friendIDs.filter({ !Data.userIsBlocked($0) }).filter({ $0 != Data.getUID() })
                })
        }
        
        _newFollowersSub = Data.firebase.childByAppendingPath("new_followers").childByAppendingPath(Data.getUID()!).pusher.subscribe({ [weak self] (let dict) in
            if let d = dict as? [String: AnyObject], let followers = Array<AnyObject>(d.values) as? [[String: AnyObject]] {
                self?._newFollowers = followers.filter({ !Data.userIsBlocked($0["uid"] as? String ?? "") })
            } else {
                self?._newFollowers = []
            }
            })
    }
    // MARK: Data
    var _searchingContactsInProgress = false {
        didSet {
            onUpdate.push(true)
        }
    }
    var _friendIDs = [String]() {
        didSet {
            onUpdate.push(true)
        }
    }
    var _newFollowers = [[String: AnyObject]]() {
        didSet {
            onUpdate.push(true)
        }
    }
    let onUpdate = Pusher<Bool>()
    
    // MARK: Contacts sync
    func addFriends() {
        let alert = UIAlertController(title: "Follow Friends", message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "📲 Add by phone number", style: .Default, handler: { (_) in
            let q = UIAlertController(title: "Add by phone number", message: nil, preferredStyle: .Alert)
            q.addTextFieldWithConfigurationHandler({ (let field) in
                field.placeholder = "Phone number"
                field.keyboardType = .PhonePad
            })
            q.addAction(UIAlertAction(title: "Never mind", style: .Cancel, handler: nil))
            q.addAction(UIAlertAction(title: "Add", style: .Default, handler: { (_) in
                if let phone = q.textFields?.first?.text?.normalizedPhone where phone != "" {
                    Data.findUserByPhone(phone, callback: { (let snapshot) in
                        if let s = snapshot {
                            // self.navigate(Route.forProfile(s.key))
                            Data.setFollowing(s.key, following: true, type: .User)
                        } else {
                            let a = UIAlertController(title: nil, message: "😯 Doesn't look like anyone with the phone number \(phone) has signed up yet.", preferredStyle: .Alert)
                            a.addAction(UIAlertAction(title: "😕 Okay", style: .Default, handler: nil))
                            a.addAction(UIAlertAction(title: "💬 Text them", style: .Default, handler: { (_) in
                                UIApplication.sharedApplication().openURL(NSURL(string: "sms://" + phone)!)
                            }))
                            NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(a, animated: true, completion: nil)
                        }
                    })
                }
            }))
            NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(q, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "🗃 Search contacts for friends", style: .Default, handler: { (_) in
            self._doContactsSync()
        }))
        alert.addAction(UIAlertAction(title: "Never mind", style: .Cancel, handler: { (_) in
            
        }))
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(alert, animated: true, completion: nil)
    }
    
    func _doContactsSync() {
        _searchingContactsInProgress = true
        Data.doContactsSync({ (let success) in
            self._searchingContactsInProgress = false
            if !success {
                self.showAlert("Something went wrong 😯")
            }
        })
    }
    
    func showAlert(text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(alert, animated: true, completion: nil)

    }
}
