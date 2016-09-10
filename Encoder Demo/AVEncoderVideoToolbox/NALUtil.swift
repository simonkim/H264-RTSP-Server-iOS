//
//  NALUtil.swift
//  Encoder Demo
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016년 Geraint Davies. All rights reserved.
//

import Foundation

enum NALUnitType: Int8 {
    case IDR = 5
    case SPS = 7
    case PPS = 8
}

class NALUtil {
    static func readNALUnitLength(at pointer: UnsafePointer<UInt8>, headerLength: Int) -> Int
    {
        var result: Int = 0
        
        for i in 0...(headerLength - 1) {
            result |= Int(pointer[i]) << ((headerLength - 1) - i) * 8
        }
        return result
    }
}

