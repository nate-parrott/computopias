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
            return 0.3
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
        presentedViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func _animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
        let vc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let view = vc.view
        view.frame = transitionContext.finalFrameForViewController(vc)
        let container = transitionContext.containerView()!
        container.addSubview(view)
        let translation = (container.bounds.size.height - view.frame.origin.y) * 0.5
        view.alpha = 0
        view.transform = CGAffineTransformMakeTranslation(0, translation + 20)
        let duration = transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            view.transform = CGAffineTransformIdentity
            view.alpha = 1
            }) { (completed) -> Void in
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
        /*let contentWidth = bounds.size.width - 40
        let contentHeight = min(contentWidth, bounds.size.height)*/
        let widthInset: CGFloat = traitCollection.horizontalSizeClass == .Compact ? 20 : 40
        let heightInset: CGFloat = traitCollection.verticalSizeClass == .Compact ? 0 : 50
        let contentWidth = bounds.size.width - widthInset * 2
        let contentHeight = bounds.size.height - heightInset * 2
        return CGRectIntegral(CGRectMake((bounds.size.width - contentWidth)/2, (bounds.size.height - contentHeight)/2, contentWidth, contentHeight))
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
