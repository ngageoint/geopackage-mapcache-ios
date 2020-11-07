//
//  MCTileServerResult.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/21/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import Foundation

 
@objc class MCTileServerResult: NSObject {
    @objc public private(set) var success: Any?
    @objc public private(set) var failure: Error?
    
    private override init() {
        super.init()
        success = nil
        failure = nil
    }
    
    public convenience init<Success, Failure>(_ arg1: Success?, _ arg2: Failure?) where Failure: Error {
        self.init()
        success = arg1
        failure = arg2
    }
}
