//
//  CommentsViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/27/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import JSQMessagesViewController
import Firebase

class CommentsViewController: JSQMessagesViewController {
    // MARK: Data
    
    var chat: Firebase!
    var _fbHandle: UInt? {
        didSet(oldValue) {
            if let h = oldValue {
                Data.firebase.removeObserverWithHandle(h)
            }
        }
    }
    var messages = [JSQMessage]()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderDisplayName = Data.getName() ?? "Unknown"
        senderId = Data.getUID()
        
        _fbHandle = chat.childByAppendingPath("messages").queryLimitedToLast(50).observeEventType(.ChildAdded, withBlock: { [weak self] (let snapshot) in
            if let dict = snapshot.value as? [String: AnyObject],
                let senderJson = dict["sender"] as? [String: AnyObject],
                let senderID = senderJson["uid"] as? String,
                let senderName = senderJson["name"] as? String,
                let date = dict["date"] as? Double,
                let text = dict["text"] as? String {
                self?.messages.append(JSQMessage(senderId: senderID, senderDisplayName: senderName, date: NSDate(timeIntervalSince1970: date), text: text))
                self?.finishReceivingMessageAnimated(true)
            }
            })
        
        title = "Comments"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(CommentsViewController.dismiss))
        
        inputToolbar.contentView.leftBarButtonItem = nil
    }
    
    func dismiss(sender: AnyObject!) {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    deinit {
        _fbHandle = nil
    }
    
    // MARK: Messaging
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let dict: [String: AnyObject] = ["text": text, "sender": Data.profileJson(), "date": NSDate().timeIntervalSince1970]
        chat.childByAppendingPath("messages").childByAutoId().setValue(dict)
        chat.childByAppendingPath("count").runTransactionBlock { (let data) -> FTransactionResult! in
            data.value = (data.value as? Int ?? 0) + 1
            return FTransactionResult.successWithValue(data)
        }
        
        finishSendingMessageAnimated(true)
    }
    
    let outgoingBubbleImage = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    let incomingBubbleImage = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == senderId ? outgoingBubbleImage : incomingBubbleImage
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            cell.textView.textColor = UIColor.whiteColor()
        } else {
            cell.textView.textColor = UIColor.blackColor()
        }
        
        // let attributes : [NSObject:AnyObject] = [NSForegroundColorAttributeName:cell.textView.textColor, NSUnderlineStyleAttributeName: 1]
        // cell.textView.linkTextAttributes = attributes
        
        //        cell.textView.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView.textColor,
        //            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle]
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
}
