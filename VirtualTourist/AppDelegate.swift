//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Amr fawzy on 4/17/19.
//  Copyright © 2019 Amr fawzy. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let dataController = DataController(modelName: "VirtualTourist")
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let travelMapViewController = navigationController.topViewController as! TravelMapViewController
        travelMapViewController.dataController = dataController
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        save()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        save()
    }
    
    func save(){
        try? dataController.viewContext.save()
    }
}

