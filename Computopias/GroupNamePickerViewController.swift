//
//  GroupNamePickerViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 4/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class GroupNamePickerViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var hashtag: UITextField!
    @IBOutlet var createButton: UIButton!
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var statusLabel: UILabel!
    
    @IBAction func done() {
        switch state {
        case .HashtagIsAvailable(tag: let tag):
            dismissViewControllerAnimated(true) {
                let editor = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Editor") as! CardEditor
                editor.hashtag = tag
                NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(editor, animated: true, completion: nil)
            }
        default: ()
        }
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        state = .EmptyHashtag
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        hashtag.becomeFirstResponder()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).stringByReplacingCharactersInRange(range, withString: string).sanitizedForFirebase.lowercaseString
        if text == "" {
            state = .EmptyHashtag
        } else {
            state = .SearchingHashtag(tag: text)
            Data.doesHashtagExist(text) { [weak self] (searchingForTag: String, exists: Bool) in
                if let s = self {
                    switch s.state {
                    case .SearchingHashtag(let tag) where tag == searchingForTag:
                        s.state = exists ? .HashtagIsUsed(tag: tag) : .HashtagIsAvailable(tag: tag)
                    default: ()
                    }
                }
            }
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    enum State {
        case EmptyHashtag
        case SearchingHashtag(tag: String)
        case HashtagIsAvailable(tag: String)
        case HashtagIsUsed(tag: String)
    }
    
    var state = State.EmptyHashtag {
        didSet {
            switch state {
            case .HashtagIsAvailable(tag: _):
                createButton.enabled = true
                createButton.alpha = 1
            default:
                createButton.enabled = false
                createButton.alpha = 0.5
            }
            
            switch state {
            case .SearchingHashtag(tag: _):
                loader.startAnimating()
            default:
                loader.stopAnimating()
            }
            
            switch state {
            case .SearchingHashtag(tag: _):
                statusLabel.text = "Checking availability..."
            case .HashtagIsAvailable(tag: let tag):
                statusLabel.text = "#\(tag) is available"
            case .HashtagIsUsed(tag: let tag):
                statusLabel.text = "#\(tag) is already being used"
            default:
                statusLabel.text = ""
            }
        }
    }
    
    override func preferredSizeForSoftModalInBounds(bounds: CGRect) -> CGSize {
        return CGSizeMake(280, 326)
    }
    
    override func preferredSoftModalPosition() -> CGPoint {
        return CGPointMake(0.5, 0.1)
    }
}
