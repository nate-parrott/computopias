//
//  AppDelegate.swift
//  Computopias
//
//  Created by Nate Parrott on 3/21/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import TCMobileProvision

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Phony.initWithAppKey("YL8BDC2SGY8FC3A", secret: "UTL284BKZOHS04KJ9D6XKXO8NV11GQFGB96VZO8NDHWALTOC45TBD4EDH3M0")
        
        srandom(UInt32(time(nil)))
        
        Appearance.setup()
        
        hideNavBarBackground()
        
        window?.rootViewController?.view.tintColor = Appearance.tint
        
        if Data.getUID() == nil || Data.getPhone() == nil {
            Data.firebase.unauth()
            delay(0.5, closure: {
                NPSoftModalPresentationController.presentViewController(UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Onboarding"))
            })
        }
        
        // Register for push notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.registerForNotificationsIfLoggedIn), name: Data.LoginDidCompleteNotification, object: nil)
        registerForNotificationsIfLoggedIn()
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        if let id = Data.getUID() {
            let token = deviceToken.hexString! + "." + (isAPNSandbox() ? "apple-sandbox" : "apple")
            print("Got push token: \(token)")
            Data.firebase.childByAppendingPath("push_tokens").childByAppendingPath(id).setValue(["a": token])
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Failed to register for push: \(error)")
    }
    
    func registerForNotificationsIfLoggedIn() {
        if Data.getUID() != nil {
            UIApplication.sharedApplication().registerForRemoteNotifications()
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge , .Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        }
    }
    
    func isAPNSandbox() -> Bool {
        if let mobileProvisionURL = NSBundle.mainBundle().URLForResource("embedded", withExtension: "mobileprovision"),
            let mobileProvisionData = NSData(contentsOfURL: mobileProvisionURL),
            let mobileProvision = TCMobileProvision(data: mobileProvisionData) {
            if let entitlements = mobileProvision.dict["Entitlements"],
                let apsEnvironment = entitlements["aps-environment"] as? String
                where apsEnvironment == "development" {
                return true
            }
        }
        return false
    }
    
    static var Shared: AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as! AppDelegate
        }
    }
    
    func hideNavBarBackground() {
        let nav = window!.rootViewController! as! UINavigationController
        nav.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        nav.navigationBar.shadowImage = UIImage()
        nav.navigationBar.translucent = true
    }
    
    /*func setupFoursquare() {
        let client = Client(clientID:       "BPQYG4XQC3DPLXNN2GGIKL1JTTAA5JBQ10N4LCC5SZWLDE1Q",
                            clientSecret:   "A2RSQ2G2OHBS4OTCI0YVTQMDTQEJUFGVF1MSYAGB5LTZ5WN5",
                            redirectURL:    "testapp123://foursquare")
        let configuration = Configuration(client:client)
        Session.setupSharedSessionWithConfiguration(configuration)
    }*/
    
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
        if url.scheme == "bubble" && url.path == "/link_contacts" {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Friends") as! UINavigationController
            let friendsVC = vc.viewControllers.first! as! FriendListViewController
            NPSoftModalPresentationController.presentViewController(vc)
            delay(1, closure: { 
                friendsVC.source._doContactsSync()
            })
        } else if url.scheme == "bubble" && url.path == "/no_thanks_dont_link_contacts" {
            Data.noThanksNoContactSyncForMe()
        }
        if url.scheme == "bubble", let route = Route.fromURL(url) where Data.getUID() != nil {
            navigateToRoute(route)
            return true
        }
        return false
    }
    
    func navigateToRoute(route: Route) {
        let vc = window!.rootViewController! as! UINavigationController
        if let presented = vc.presentedViewController {
            presented.dismissViewControllerAnimated(true, completion: { 
                self.navigateToRoute(route)
            })
        } else {
            vc.pushViewController(NavigableViewController.FromRoute(route), animated: true)
        }
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
    
    var _networkActivityCounter = 0
    func incrementNetworkActivityCounter(i: Int) {
        _networkActivityCounter += i
        let shouldBeVisible = (_networkActivityCounter > 0)
        if shouldBeVisible != UIApplication.sharedApplication().networkActivityIndicatorVisible {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = shouldBeVisible
        }
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

