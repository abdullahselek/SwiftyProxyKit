//
//  SwiftyProxyServer.swift
//  SwiftyProxyKit
//
//  Copyright © 2018 Abdullah Selek. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

open class SwiftyProxyServer {

    open static let shared = SwiftyProxyServer()
    internal var incomingRequests: [FileHandle: CFHTTPMessage]
    var fileHandler: FileHandle?
    
    private init() {
        incomingRequests = [FileHandle: CFHTTPMessage]()
    }

    @objc internal func receiveIncomingConnectionNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: FileHandle], let incomingFileHandle = userInfo[NSFileHandleNotificationFileHandleItem] else {
            return
        }
        let message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
        incomingRequests[incomingFileHandle] = message
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SwiftyProxyServer.receiveIncomingDataNotification(notification:)),
                                               name: Notification.Name.NSFileHandleDataAvailable,
                                               object: incomingFileHandle)
        incomingFileHandle.waitForDataInBackgroundAndNotify()
        if let fileHandler = fileHandler {
            fileHandler.acceptConnectionInBackgroundAndNotify()
        }
    }

    @objc func receiveIncomingDataNotification(notification: NSNotification) {

    }
    
    internal func stopReceiving(incomingFileHandle: FileHandle, stopHandling: Bool) {
        if stopHandling {
            print("SwiftyProxyServer: File closed and Incoming Request removed! \(requestType(fileHandle: incomingFileHandle, incomingRequests: incomingRequests) ??  "")")
            incomingFileHandle.closeFile()
        }
        NotificationCenter.default.removeObserver(self, name: Notification.Name.NSFileHandleDataAvailable, object: incomingFileHandle)
        incomingRequests[incomingFileHandle] = nil
    }
    
    internal func requestType(fileHandle: FileHandle, incomingRequests: [FileHandle: CFHTTPMessage]) -> String? {
        guard let incomingRequest = incomingRequests[fileHandle] else {
            return nil
        }
        guard let httpHeaderFields = CFHTTPMessageCopyAllHeaderFields(incomingRequest) else {
            return nil
        }
        guard var rawPointer = CFDictionaryGetValue(httpHeaderFields.takeRetainedValue(), "RequestType") else {
            return nil
        }
        let requestType = withUnsafePointer(to: &rawPointer) { ptr -> String in
            return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        return requestType
    }

}
