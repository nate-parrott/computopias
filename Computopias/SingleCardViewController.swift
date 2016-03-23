//
//  SingleCardViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/23/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class SingleCardViewController: UIViewController {
    @IBOutlet var cardView: CardView!
    
    var hashtag: String!
    var cardFirebase: Firebase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardView.cardFirebase = cardFirebase
        cardView.backgroundColor = Appearance.colorForHashtag(hashtag)
        cardView.hashtag = hashtag
        _fbHandle = cardFirebase.observeEventType(FEventType.Value, withBlock: { [weak self] (let snapshot) -> Void in
            if let json = snapshot.value as? [String: AnyObject] {
                self?.cardView.importJson(json)
                for item in self?.cardView.items ?? [] {
                    item.editMode = false
                    item.templateEditMode = false
                }
            }
            })
    }
    deinit {
        if let h = _fbHandle {
            Data.firebase.removeObserverWithHandle(h)
        }
    }
    var _fbHandle: UInt?
}
