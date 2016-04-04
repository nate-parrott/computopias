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
        if Data.ALLOW_FAKE_LOGIN {
            let prompt = UIAlertController(title: "Enter your phone number:", message: nil, preferredStyle: .Alert)
            prompt.addTextFieldWithConfigurationHandler({ (let field) in
                field.keyboardType = .PhonePad
            })
            prompt.addAction(UIAlertAction(title: "Okay", style: .Default, handler: { (_) in
                let phone = (prompt.textFields![0].text ?? "").normalizedPhone
                if phone != "" {
                    self.phoneState = .Success(number: phone, firebaseToken: "FAKE")
                }
            }))
            presentViewController(prompt, animated: true, completion: nil)
        } else {
            Phony.sharedPhony().verifyPhoneNumber { (let phoneNumberOpt, let firebaseTokenOpt, let errorOpt) in
                if let phone = phoneNumberOpt, let firebaseToken = firebaseTokenOpt {
                    self.phoneState = .Success(number: phone, firebaseToken: firebaseToken)
                } else {
                    self.phoneState = .Error(err: errorOpt)
                }
            }
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        loginInProgress = true
        
        let callback = {
            (let success: Bool) in
            if success {
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                self.loginInProgress = false
            }
        }
        let name = nameField.text!
        if phoneState.firebaseToken! == "FAKE" && Data.ALLOW_FAKE_LOGIN {
            Data.fakeLogin(phoneState.number!, name: name, callback: callback)
        } else {
            Data.logIn(phoneState.number!, name: name, firebaseToken: phoneState.firebaseToken!, callback: callback)
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
        case Success(number: String, firebaseToken: String)
        var number: String? {
            get {
                switch self {
                case .Success(number: let n, firebaseToken: _): return n.normalizedPhone
                default: return nil
                }
            }
        }
        var firebaseToken: String? {
            get {
                switch self {
                case .Success(number: _, firebaseToken: let t): return t
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
        case .Success(number: let n, firebaseToken: _):
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
    
    override func preferredSoftModalPosition() -> CGPoint {
        return CGPointMake(0.5, 0.25)
    }
}
