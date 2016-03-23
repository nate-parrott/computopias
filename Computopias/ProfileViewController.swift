//
//  ProfileViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        name.text = Data.getName()
        bio.text = Data.getBio()
        phone.text = Data.getPhone()
        bio.layer.borderColor = UIColor.blackColor().CGColor
        bio.layer.borderWidth = 1
        update()
    }
    
    @IBOutlet var name: UITextField!
    @IBOutlet var bio: UITextView!
    @IBOutlet var phone: UITextField!
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        bio.becomeFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        delay(0) { () -> () in
            self.update()
        }
        return true
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        update()
    }
    
    func update() {
        doneButton.enabled = (name.text ?? "").utf16.count > 0
    }
    
    @IBOutlet var doneButton: UIBarButtonItem!
    
    @IBAction func done() {
        Data.setName(name.text ?? "")
        Data.setBio(bio.text ?? "")
        Data.setPhone(phone.text ?? "")
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
