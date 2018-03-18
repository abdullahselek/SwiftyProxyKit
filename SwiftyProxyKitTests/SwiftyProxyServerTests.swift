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
            var isStarted = false
            
            beforeSuite {
                proxyServer = SwiftyProxyServer.shared
                isStarted = proxyServer.start()
            }
            
            context("SwiftyProxyServer.init()", {
                it("should return a valid instance", closure: {
                    expect(proxyServer).notTo(beNil())
                    expect(proxyServer.incomingRequests).notTo(beNil())
                })
            })

            context("SwiftyProxyServer.start()", {
                it("starts", closure: {
                    expect(isStarted).to(beTrue())
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
                        let incomingRequest = proxyServer.incomingRequests[fileHandle]
                        expect(incomingRequest).notTo(beNil())
                    })
                })
            })

            describe("SwiftyProxyServer.stopReceiving(incomingFileHandle:stopHandling:)", {
                context("when stopHandling set as true", {
                    let fileHandle = FileHandle(fileDescriptor: 10, closeOnDealloc: true)
                    let fakeNotification = NSNotification(name: Notification.Name.NSFileHandleDataAvailable,
                                                          object: nil,
                                                          userInfo: [NSFileHandleNotificationFileHandleItem: fileHandle])
                    
                    beforeEach {
                        proxyServer.receiveIncomingConnectionNotification(notification: fakeNotification)
                        proxyServer.stopReceiving(incomingFileHandle: fileHandle, stopHandling: true)
                    }

                    it("stops handling and removes file handle", closure: {
                        let incomingRequest = proxyServer.incomingRequests[fileHandle]
                        expect(incomingRequest).to(beNil())
                    })
                })
            })

            context("SwiftyProxyServer.stop()", {
                let fileHandle = FileHandle(fileDescriptor: 10, closeOnDealloc: true)
                let fakeNotification = NSNotification(name: Notification.Name.NSFileHandleDataAvailable,
                                                      object: nil,
                                                      userInfo: [NSFileHandleNotificationFileHandleItem: fileHandle])

                beforeEach {
                    proxyServer.receiveIncomingConnectionNotification(notification: fakeNotification)
                    proxyServer.stop()
                }

                it("stops", closure: {
                    expect(proxyServer.incomingRequests[fileHandle]).to(beNil())
                })
            })

            context("SwiftyProxyServer.fileSize(fromPath:)", {
                beforeEach {
                    let data = "Abdullah Selek - SwiftyProxyServer".data(using: String.Encoding.utf8)!
                    FileManager.default.createFile(atPath: "test.txt", contents: data, attributes: nil)
                }
                
                it("returns formatted file size", closure: {
                    let fileSize = proxyServer.fileSize(fromPath: "test.txt")
                    expect(fileSize).notTo(beNil())
                })
            })
        }
    }

}
