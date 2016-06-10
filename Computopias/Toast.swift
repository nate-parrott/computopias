
//
//  UIWindow+Toast.swift
//  Computopias
//
//  Created by Nate Parrott on 6/5/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

extension UIViewController {
    func showToast(title: String, callback: () -> ()) -> ToastView {
        let t = ToastView(title: title, callback: callback)
        t.present(view)
        return t
    }
}

class ToastView: UIView {
    init(title: String, callback: () -> ()) {
        super.init(frame: CGRectZero)
        addSubview(bgView)
        bgView.backgroundColor = UIColor.blackColor()
        addSubview(label)
        label.font = UIFont.systemFontOfSize(16)
        label.textColor = UIColor.whiteColor()
        label.text = title
        self.callback = callback
        tapRec = UITapGestureRecognizer(target: self, action: #selector(ToastView.tapped))
        addGestureRecognizer(tapRec)
        swipeRec = UISwipeGestureRecognizer(target: self, action: #selector(ToastView.dismiss))
        swipeRec.direction = .Up
        addGestureRecognizer(swipeRec)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    let padding: CGFloat = 12
    let label = UILabel()
    let bgView = UIView()
    var tapRec: UITapGestureRecognizer!
    var swipeRec: UISwipeGestureRecognizer!
    var callback: (() -> ())?
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRectInset(bounds, padding, padding)
        bgView.frame = CGRectMake(0, -500, bounds.size.width, bounds.size.height + 500)
    }
    override func sizeThatFits(size: CGSize) -> CGSize {
        return label.sizeThatFits(size.padded(-padding)).padded(padding)
    }
    func tapped() {
        if let cb = callback {
            cb()
        }
        dismiss()
    }
    func present(view: UIView) {
        _dismissed = false
        view.addSubview(self)
        var size = sizeThatFits(view.bounds.size)
        size.width = view.bounds.size.width
        frame = CGRectMake(0, -size.height, size.width, size.height)
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.AllowUserInteraction], animations: { 
            self.frame = CGRectMake(0, 0, size.width, size.height)
            }) { (_) in
                delay(2, closure: {
                    self.dismiss()
                })
        }
    }
    var _dismissed = false
    func dismiss() {
        if !_dismissed {
            _dismissed = true
            
            UIView.animateWithDuration(0.3, delay: 0, options: [.AllowUserInteraction], animations: { 
                self.frame = CGRectMake(0, -self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)
                }, completion: { (_) in
                    self.removeFromSuperview()
            })
        }
    }
}
