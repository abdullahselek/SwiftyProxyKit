//
//  SwiftyProxyServer.swift
//  SwiftyProxyKitTests
//
//  Created by Abdullah Selek on 12.03.18.
//  Copyright © 2018 Abdullah Selek. All rights reserved.
//

import Quick
import Nimble

@testable import SwiftyProxyKit

class SwiftyProxyServerTests: QuickSpec {

    override func spec() {
        describe("SwiftyProxyServer Tests") {
            var proxyServer: SwiftyProxyServer!
            
            beforeSuite {
                proxyServer = SwiftyProxyServer.shared
            }
            
            context("SwiftyProxyServer.init()", {
                it("should return a valid instance", closure: {
                    expect(proxyServer).notTo(beNil())
                    expect(proxyServer.incomingRequests).notTo(beNil())
                })
            })
            
            describe("SwiftyProxyServer.receiveIncomingConnectionNotification(notification:)", {
                context("when notification has a valid file handle", {
                    let fileHandle = FileHandle(fileDescriptor: 10, closeOnDealloc: true)
                    let fakeNotification = NSNotification(name: Notification.Name.NSFileHandleDataAvailable,
                                                          object: nil,
                                                          userInfo: [NSFileHandleNotificationFileHandleItem: fileHandle])

                    beforeEach {
                        proxyServer.receiveIncomingConnectionNotification(notification: fakeNotification)
                    }

                    it("adds file handle to incoming requests", closure: {
                        let incomingRequest = CFDictionaryGetValue(proxyServer.incomingRequests, Unmanaged.passUnretained(fileHandle).toOpaque());
                        expect(incomingRequest).notTo(beNil())
                    })
                })
            })
        }
    }

}
