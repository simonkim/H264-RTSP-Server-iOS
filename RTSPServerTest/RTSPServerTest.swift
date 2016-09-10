//
//  RTSPServerTest.swift
//  RTSPServerTest
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016년 Geraint Davies. All rights reserved.
//

import XCTest

class RTSPServerTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        var bytes: [UInt8] = [ 0, 0, 0, 2, 0x55, 0x66]
        _ = NALUtil.readNALUnitLength(at: &bytes, headerLength: 4)
        
    }

}
