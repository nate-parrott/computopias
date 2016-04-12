//
//  HashtagCardStack.swift
//  Computopias
//
//  Created by Nate Parrott on 4/8/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class HashtagCardStack: CardFeedStack {
    var hashtag: String!
    var source: HashtagFeedSource?
    override func becameVisible() {
        super.becameVisible()
        source = HashtagFeedSource(hashtag: hashtag)
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        textColor = UIColor.whiteColor()
        tintColor = UIColor.whiteColor()
    }
    override func noLongerVisible() {
        super.noLongerVisible()
        source = nil
    }
    override func cardIDs() -> [String] {
        return source?.cardIDs ?? []
    }
    override func cardDictForID(id: String) -> [String : AnyObject]? {
        return source?.cardsByID[id]
    }
    override func renderTopControls(view: UIView, rect: CGRect) {
        super.renderTopControls(view, rect: rect)
        if let text = source?.groupInfoText {
            let label = view.elasticGetChildWithKey("label", creationBlock: { () -> UIView in
                let l = UILabel()
                l.numberOfLines = 0
                l.textAlignment = .Center
                l.userInteractionEnabled = true
                l.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(HashtagCardStack._editGroupInfo)))
                return l
            }) as! UILabel
            label.attributedText = text
            label.textColor = textColor
            label.frame = CGRectInset(rect, rect.size.width * 0.15, 20)
        }
    }
    override func renderBottomControls(view: UIView, rect: CGRect) {
        super.renderBottomControls(view, rect: rect)
        
        let followButton = view.elasticGetChildWithKey("follow") { [weak self] () -> UIView in
            return CUButton(title: "", action: {
                self?.source?.toggleFollowing()
            })
        } as! CUButton
        let following = source?.following ?? false
        followButton.setTitle(following ? "Following" : "Follow", forState: .Normal)
        
        let postButton = view.elasticGetChildWithKey("post") { [weak self] () -> UIView in
            return CUButton(title: "Post", action: { 
                self?.source?.addPost()
            })
        } as! CUButton
        
        let pad: UIButton -> AnyObject = { [EVInset($0, UIEdgeInsetsMake(0, self.padding/2, 0, self.padding/2))] }
        EVComplexLayout(false, rect, [EVVertical(), EVLayoutAlignCenter(), [EVHorizontal(), EVLayoutAlignCenter(), pad(postButton), pad(followButton)]])
    }
    
    @objc func _editGroupInfo() {
        source?.editGroupInfo()
    }
    // MARK: Empty state content
    override func renderUnderlay(view: UIView, rect: CGRect) {
        super.renderUnderlay(view, rect: rect)
        if let (str, action) = source?.emptyStateContent {
            let label = view.elasticGetChildWithKey("emptyState", creationBlock: { () -> ElasticRenderedObject in
                let l = LabelNode()
                l.percentWidth = 0.7
                return l
            }) as! LabelNode
            label.frame = rect
            label.attributedString = str
            label.onTap = action
        }
    }
}
