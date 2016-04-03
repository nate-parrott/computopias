//
//  OnboardingViewController.swift
//  Computopias
//
//  Created by Nate Parrott on 3/28/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController, UITextFieldDelegate {
    // MARK: UI Outlets
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var phoneButton: UIButton!
    @IBOutlet var loginLoader: UIActivityIndicatorView!
    
    @IBAction func verifyPhone(sender: AnyObject) {
        phoneState = .InProgress
        let a = UIAlertController(title: nil, message: "what's your phone number", preferredStyle: .Alert)
        a.addTextFieldWithConfigurationHandler { (let f) in
            f.keyboardType = .PhonePad
        }
        a.addAction(UIAlertAction(title: "Done", style: .Default, handler: { (_) in
            if let t = a.textFields?.first?.text where t != "" {
                self.phoneState = .Success(number: t)
            } else {
                self.phoneState = .Error(err: nil)
            }
        }))
        presentViewController(a, animated: true, completion: nil)
    }
    
    @IBAction func done(sender: AnyObject) {
        loginInProgress = true
        Data.logIn(phoneState.number!) { (let success) in
            if success {
                Data.setName(self.nameField.text!)
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                self.loginInProgress = false
            }
        }
    }
    
    override func preferredSizeForSoftModalInBounds(bounds: CGRect) -> CGSize {
        return CGSizeMake(280, 265)
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        for v in [phoneButton, nameField] {
            v.layer.cornerRadius = 6
            v.clipsToBounds = true
        }
        phoneState = .None
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OnboardingViewController.textChanged), name: UITextFieldTextDidChangeNotification, object: nameField)
    }
    
    override func allowUserToDismissSoftModal() -> Bool {
        return false
    }
    
    var loginInProgress = false {
        didSet {
            _updateUI()
        }
    }
    
    // MARK: Phone verification
    enum PhoneVerificationState {
        case None
        case InProgress
        case Error(err: NSError?)
        case Success(number: String)
        var number: String? {
            get {
                switch self {
                case .Success(number: let n): return n.normalizedPhone
                default: return nil
                }
            }
        }
    }
    
    var phoneState: PhoneVerificationState = .None {
        didSet(oldVal) {
            _updateUI()
            if oldVal.number == nil && phoneState.number != nil && (nameField.text ?? "") == "" {
                nameField.becomeFirstResponder()
            }
        }
    }
    
    func _updateUI() {
        doneButton.enabled = phoneState.number != nil && (nameField.text ?? "") != "" && !loginInProgress
        
        for element in [phoneButton, nameField] {
            element.alpha = loginInProgress ? 0.5 : 1
        }
        view.userInteractionEnabled = !loginInProgress
        if loginInProgress {
            loginLoader.startAnimating()
        } else {
            loginLoader.stopAnimating()
        }
        
        
        loader.stopAnimating()
        var phoneButtonText = "Verify your phone number…"
        var phoneButtonEnabled = true
        switch phoneState {
        case .InProgress:
            loader.startAnimating()
            phoneButtonEnabled = false
            phoneButtonText = "Verifying…"
        case .Error(err: _):
            phoneButtonText = "Error 🙀 Try again?"
        case .Success(number: let n):
            phoneButtonText = "Hi, \(n)!"
        default: ()
        }
        
        phoneButton.enabled = phoneButtonEnabled
        phoneButton.setTitle(phoneButtonText, forState: .Normal)
    }
    
    @IBAction func textChanged(notif: NSNotificationCenter) {
        _updateUI()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
