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
        if url.scheme == "computopias" {
            var path = url.path ?? ""
            path = path.stringByReplacingOccurrencesOfString("/hashtag/", withString: "/#")
            if let f = path.characters.first where f == "/".characters.first! {
                path = path[1...path.characters.count]
            }
            let nav = NavViewController.shared
            // dismiss all modals:
            var modals = [UIViewController]()
            var vc: UIViewController = nav
            while let child = vc.presentingViewController {
                modals.append(child)
                vc = child
            }
            while let v = modals.last {
                v.dismissViewControllerAnimated(false, completion: nil)
                modals.removeLast()
            }
            
            NavViewController.shared.navigate(path)
            return true
        }
        return false
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        srandom(UInt32(time(nil)))
        // Override point for customization after application launch.
        return true
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

