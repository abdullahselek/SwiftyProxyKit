//
//  AppDelegate.swift
//  Sample-iOS
//
//  Created by Abdullah Selek on 21.03.18.
//  Copyright © 2018 Abdullah Selek. All rights reserved.
//

import UIKit
import SwiftyProxyKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let proxyServer = SwiftyProxyServer.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        _ = proxyServer.start()
        return true
    }

}

extension AppDelegate: SwiftyProxyServerDataSource {

    func responseData() -> Data {
        let response = "This is a response from SwiftyProxyServer for debugging.".data(using: String.Encoding.utf8)!
        return response
    }

}
