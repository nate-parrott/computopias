//
//  AppDelegate.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        srandom(UInt32(time(nil)))
        
        Appearance.setup()
        
        let nav = window!.rootViewController as! UINavigationController
        nav.view.tintColor = Appearance.tint
        
        var defaultRoute = Data.lastHomeScreenShownWasFriendsList ? Route.ProfilesList : Route.HashtagsList
        if Data.getPhone() == nil {
            defaultRoute = Route.ProfilesList
            delay(0.5, closure: {
                NPSoftModalPresentationController.presentViewController(UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Onboarding"))
            })
        }
        nav.viewControllers = [NavigableViewController.FromRoute(defaultRoute)]
        
        return true
    }
    
    var _window: CMWindow?
    var window: UIWindow? {
        get {
            if _window == nil {
                _window = CMWindow(frame: UIScreen.mainScreen().bounds)
            }
            return _window
        }
        set(val) {
            // do nothing
        }
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if url.scheme == "bubble", let route = Route.fromURL(url) where Data.getUID() != nil {
            navigateToRoute(route)
            return true
        }
        return false
    }
    
    func navigateToRoute(route: Route) {
        let nav = window!.rootViewController as! UINavigationController
        let curPage = nav.viewControllers.last as? NavigableViewController
        curPage?.navigate(route)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    /*
    - (UIWindow *)window {
    if (!_window) {
    _window = [[CMWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.windowLevel = UIWindowLevelNormal;
    }
    return _window;
    }
    
    - (void)setWindow:(UIWindow *)window {
    // DO NOTHING (???)
    }
*/

}

