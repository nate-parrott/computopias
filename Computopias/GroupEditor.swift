//
//  GroupEditor.swift
//  Computopias
//
//  Created by Nate Parrott on 4/4/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import Firebase

class GroupEditor: UIViewController {
    var hashtag: String!
    var info: [String: AnyObject]? {
        didSet {
            descriptionField.text = info?["description"] as? String ?? ""
        }
    }
    @IBOutlet var descriptionField: UITextView!
    var fields: [UIView] {
        get {
            return [descriptionField]
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(GroupEditor.dismiss))
        title = "#\(hashtag) Settings"
        automaticallyAdjustsScrollViewInsets = false
    }
    func dismiss() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        for field in fields {
            field.alpha = 0.5
            field.userInteractionEnabled = false
        }
        Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("info").observeSingleEventOfType(.Value) { (let snapshot: FDataSnapshot!) in
            self.info = snapshot.value as? [String: AnyObject] ?? [String: AnyObject]()
            for field in self.fields {
                field.alpha = 1
                field.userInteractionEnabled = true
            }
        }
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if var info = self.info {
            info["description"] = descriptionField.text ?? ""
            Data.firebase.childByAppendingPath("hashtags").childByAppendingPath(hashtag).childByAppendingPath("info").setValue(info)
        }
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
