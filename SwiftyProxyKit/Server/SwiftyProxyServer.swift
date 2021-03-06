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

import Foundation
import SystemConfiguration
import CFNetwork

public protocol SwiftyProxyServerDataSource: class {
    func responseData() -> Data?
}

open class SwiftyProxyServer {

    open static let shared = SwiftyProxyServer()
    open var dataSource: SwiftyProxyServerDataSource?
    internal var socket: CFSocket!
    internal var incomingRequests: [FileHandle: CFHTTPMessage]
    internal var fileHandler: FileHandle!
    
    private init() {
        incomingRequests = [FileHandle: CFHTTPMessage]()
    }
    
    open func start() -> Bool {
        guard let socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, nil, nil) else {
            print("SwiftyProxyServer unable to create socket.")
            return false
        }
        self.socket = socket
        var reuse = true
        let fileDescriptor = CFSocketGetNative(socket)
        if (setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int>.size)) != 0) {
            print("SwiftyProxyServer unable to set socket options.")
            return false
        }

        var address = sockaddr_in()
        memset(&address, 0, MemoryLayout<sockaddr_in>.size)
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = CFSwapInt32HostToBig(INADDR_ANY)
        address.sin_port = in_port_t(8080)

        let addressData = NSData(bytes: &address, length: MemoryLayout.size(ofValue: address))
        let error = CFSocketSetAddress(socket, addressData as CFData)
        if error != .success {
            print("SwiftyProxyServer unable to bind socket to address.")
            return false
        }

        fileHandler = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SwiftyProxyServer.receiveIncomingConnectionNotification(notification:)),
                                               name: Notification.Name.NSFileHandleConnectionAccepted,
                                               object: nil)
        fileHandler.acceptConnectionInBackgroundAndNotify()
        print("SwiftyProxyServer started at port 8080!")
        return true
    }
    
    open func stop() {
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.NSFileHandleConnectionAccepted,
                                                  object: nil)
        fileHandler.closeFile()

        for incomingFileHandle in incomingRequests.keys {
            print("SwiftyProxyServer stop receiving for fileHandle: \(requestType(fileHandle: incomingFileHandle, incomingRequests: incomingRequests) ?? "")")
            stopReceiving(incomingFileHandle: incomingFileHandle, stopHandling: true)
        }

        CFSocketInvalidate(socket)
        print("SwiftyProxyServer stopped!")
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
        fileHandler.acceptConnectionInBackgroundAndNotify()
    }

    @objc func receiveIncomingDataNotification(notification: NSNotification) {
        guard let incomingFileHandle = notification.object as? FileHandle else {
            return
        }
        let data = incomingFileHandle.availableData
        if data.count == 0 {
            print("Stop Receiving for file handle: no data: \(requestType(fileHandle: incomingFileHandle, incomingRequests: incomingRequests) ?? "")")
            stopReceiving(incomingFileHandle: incomingFileHandle, stopHandling: false)
            return
        }
        guard let incomingRequest = incomingRequests[incomingFileHandle] else {
            print("Stop Receiving for file handle: no incoming request: \(requestType(fileHandle: incomingFileHandle, incomingRequests: incomingRequests) ?? "")")
            stopReceiving(incomingFileHandle: incomingFileHandle, stopHandling: true)
            return
        }
        data.withUnsafeBytes { (p: UnsafePointer<UInt8>) -> Void in
            if !CFHTTPMessageAppendBytes(incomingRequest, p, data.count) {
                print("Stop Receiving for file handle: append bytes failed: \(requestType(fileHandle: incomingFileHandle, incomingRequests: incomingRequests) ?? "")")
                stopReceiving(incomingFileHandle: incomingFileHandle, stopHandling: true)
                return
            }
        }
        if CFHTTPMessageIsHeaderComplete(incomingRequest) {
            _ = startResponse(fileHandle: incomingFileHandle)
            print("Stop Receiving for file handle: header finished: \(requestType(fileHandle: incomingFileHandle, incomingRequests: incomingRequests) ?? "")")
            stopReceiving(incomingFileHandle: incomingFileHandle, stopHandling: false)
        }
        incomingFileHandle.waitForDataInBackgroundAndNotify()
    }
    
    internal func startResponse(fileHandle: FileHandle) -> Bool {
        guard let dataSource = dataSource else {
            print("SwiftyProxyServer set dataSource and override responseData to feed data!")
            return false
        }
        let responseCode = 200
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, responseCode, nil, kCFHTTPVersion1_1)
        let retainedResponse = response.takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(retainedResponse, "Content-Type" as CFString, "text/plain" as CFString)
        guard let data = dataSource.responseData() else {
            print("SwiftyProxyServer no data provided from dataSource!")
            return false
        }
        let dataLength = String(format: "%ld", CUnsignedLong(data.count))
        CFHTTPMessageSetHeaderFieldValue(retainedResponse, "Content-Length" as CFString, dataLength as CFString)

        guard let headerData = CFHTTPMessageCopySerializedMessage(retainedResponse) else {
            print("SwiftyProxyServer can't serialize header data.")
            return false
        }

        fileHandle.write(headerData.takeRetainedValue() as Data)
        print(String(format: "SwiftyProxyServer writing data: %lu", CUnsignedLong(data.count)))
        fileHandle.write(data)
        return true
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
    
    internal func fileSize(fromPath path: String) -> String? {
        var size: Any?
        do {
            size = try FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size]
        } catch (let error) {
            print("SwiftyProxyServer file size error: \(error)")
            return nil
        }
        guard let fileSize = size as? UInt64 else {
            return nil
        }
        
        // bytes
        if fileSize < 1023 {
            return String(format: "%lu bytes", CUnsignedLong(fileSize))
        }
        // KB
        var floatSize = Float(fileSize / 1024)
        if floatSize < 1023 {
            return String(format: "%.1f KB", floatSize)
        }
        // MB
        floatSize = floatSize / 1024
        if floatSize < 1023 {
            return String(format: "%.1f MB", floatSize)
        }
        // GB
        floatSize = floatSize / 1024
        return String(format: "%.1f GB", floatSize)
    }

}
