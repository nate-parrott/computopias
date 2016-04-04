//
//  NPSoftModalPresentationController.swift
//  scratchx
//
//  Created by Nate Parrott on 10/14/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class NPSoftModalPresentationController: UIPresentationController, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    class func getViewControllerForPresentationInWindow(window: UIWindow) -> UIViewController {
        var parent = window.rootViewController!
        while let modal = parent.presentedViewController {
            if modal.isBeingDismissed() {
               break
            } else {
                parent = modal
            }
        }
        return parent
    }
    
    class func getViewControllerForPresentation() -> UIViewController {
        return getViewControllerForPresentationInWindow(UIApplication.sharedApplication().windows.first!)
    }
    
    class func presentViewController(viewController: UIViewController) {
        presentViewController(viewController, fromViewController: getViewControllerForPresentationInWindow(UIApplication.sharedApplication().windows.first!))
    }
    
    class func presentViewController(viewController: UIViewController, fromViewController: UIViewController) {
        let presenter = NPSoftModalPresentationController(presentedViewController: viewController, presentingViewController: fromViewController)
        viewController.transitioningDelegate = presenter
        viewController.modalPresentationStyle = .Custom
        fromViewController.presentViewController(viewController, animated: true, completion: nil)
    }
    
    private var _dimView: UIView!
    private var _tapRec: UITapGestureRecognizer!
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        let toVC = transitionContext!.viewControllerForKey(UITransitionContextToViewControllerKey)!
        if toVC === self.presentedViewController {
            // we're presenting a modal:
            return 0.7
        } else {
            // we're dismissing:
            return 0.3
        }
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        if toVC === self.presentedViewController {
            _animatePresentation(transitionContext)
        } else {
            _animateDismissal(transitionContext)
        }
    }
    
    override func presentationTransitionWillBegin() {
        _dimView = UIView()
        _dimView.backgroundColor = UIColor.blackColor()
        _dimView.alpha = 0
        
        _tapRec = UITapGestureRecognizer(target: self, action: #selector(NPSoftModalPresentationController._tappedDimView(_:)))
        _dimView.addGestureRecognizer(_tapRec)
        
        containerView!.addSubview(_dimView)
        _dimView.frame = containerView!.bounds
        presentingViewController.transitionCoordinator()!.animateAlongsideTransition({ (let ctx) -> Void in
            self._dimView.alpha = 0.6
            }) { (let ctx) -> Void in
                
        }
    }
    
    @objc private func _tappedDimView(sender: UITapGestureRecognizer) {
        if presentedViewController.allowUserToDismissSoftModal() {
            presentedViewController.dismissViewControllerAnimated(true, completion: nil)
        } else {
            UIView.animateWithDuration(0.05, delay: 0, options: .CurveEaseOut, animations: {
                self.presentedView()!.transform = CGAffineTransformMakeScale(1.1, 1.1)
                }, completion: { (_) in
                    UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
                        self.presentedView()!.transform = CGAffineTransformIdentity
                        }, completion: nil)
            })
        }
    }
    
    private func _animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
        let vc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let view = vc.view
        
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        view.frame = transitionContext.finalFrameForViewController(vc)
        let container = transitionContext.containerView()!
        container.addSubview(view)
        let translation = (container.bounds.size.height - view.frame.origin.y) * 0.5
        view.alpha = 0
        view.transform = CGAffineTransformMakeTranslation(0, translation + 20)
        let duration = transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.2, options: [], animations: {
            view.transform = CGAffineTransformIdentity
            view.alpha = 1
            }) { (completed) in
                transitionContext.completeTransition(true)
        }
    }
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        _dimView.frame = containerView!.bounds
        if let view = presentedView() {
            let frame = frameOfPresentedViewInContainerView()
            view.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height)
            view.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        }
    }
    override func frameOfPresentedViewInContainerView() -> CGRect {
        let bounds = containerView!.bounds
        let size = presentedViewController.preferredSizeForSoftModalInBounds(bounds)
        let preferredCenter = presentedViewController.preferredSoftModalPosition()
        let origin = CGPointMake((bounds.size.width - size.width) * preferredCenter.x, (bounds.size.height - size.height) * preferredCenter.y)
        return CGRectMake(round(origin.x), round(origin.y), round(size.width), round(size.height))
        // return CGRectIntegral(CGRectMake((bounds.size.width - size.width)/2, (bounds.size.height - size.height)/2, size.width, size.height))
    }
    override func shouldRemovePresentersView() -> Bool {
        return false
    }
    override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator()!.animateAlongsideTransition({ (let ctx) -> Void in
            self._dimView.alpha = 0
            }) { (let ctx) -> Void in
                self._dimView.removeFromSuperview()
        }
    }
    private func _animateDismissal(transitionContext: UIViewControllerContextTransitioning) {
        let vc = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let view = vc.view
        let container = transitionContext.containerView()!
        let translation = (container.bounds.size.height - view.frame.origin.y) * 0.5
        let duration = transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            view.transform = CGAffineTransformMakeTranslation(0, translation)
            // view.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(0, translation), CGFloat(M_PI) * 0.3)
            view.alpha = 0
            }) { (completed) -> Void in
                view.alpha = 1;
                transitionContext.completeTransition(true)
        }
    }
    override func dismissalTransitionDidEnd(completed: Bool) {
        
    }
    
    // MARK: Transition Delegate
    // (private implementation, used for presentViewController())
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        return NPSoftModalPresentationController(presentedViewController: presented, presentingViewController: presenting)
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented.presentationController as? NPSoftModalPresentationController
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed.presentationController as? NPSoftModalPresentationController
    }
}

extension UIViewController {
    func preferredSizeForSoftModalInBounds(bounds: CGRect) -> CGSize {
        /*let contentWidth = bounds.size.width - 40
         let contentHeight = min(contentWidth, bounds.size.height)*/
        let widthInset: CGFloat = traitCollection.horizontalSizeClass == .Compact ? 40 : 60
        let heightInset: CGFloat = traitCollection.verticalSizeClass == .Compact ? 10 : 70
        let contentSize = CGSizeMake(bounds.size.width - widthInset * 2, bounds.size.height - heightInset * 2)
        return contentSize
    }
    func allowUserToDismissSoftModal() -> Bool {
        return true
    }
    func preferredSoftModalPosition() -> CGPoint {
        return CGPointMake(0.5, 0.5)
    }
}
