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
                })
            })
        }
    }

}
