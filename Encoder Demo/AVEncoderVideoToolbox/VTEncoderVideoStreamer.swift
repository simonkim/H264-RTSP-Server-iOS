//
//  VideoCaptureTest.swift
//  Encoder Demo
//
//  Created by Simon Kim on 2016. 9. 10..
//  Copyright © 2016년 Geraint Davies. All rights reserved.
//

import Foundation

struct BitrateMeasure {
    var firstPTS: Double = -1
    var bps: Int = 0
    var bytes: Int = 0
    
    mutating func measure(dataArray:[Data], pts:Double) -> Int {
        if firstPTS < 0 {
            firstPTS = pts
        } else if (pts - self.firstPTS) < 1 {
            bytes += dataArray.reduce(0) { $0 + $1.count }
            bps = self.bytes * 8
        }
        
        return self.bps
    }
}

class VTEncoderVideoStreamer {
    var rtspServer: RTSPServer?
    
    var videoSize: CGSize = CGSize()
    var parameterSets: H264ParameterSets?
    
    var bpsMeter: BitrateMeasure = BitrateMeasure()
    var preferredBitrate: Int = 1024 * 1024
    
    lazy var encoder: VTEncoder = {
        let encoder = VTEncoder(width: Int32(self.videoSize.width), height: Int32(self.videoSize.height), bitrate: self.preferredBitrate)
        encoder.onEncoded = { status, infoFlags, sampleBuffer in
            if let sampleBuffer = sampleBuffer,
                let bb = CMSampleBufferGetDataBuffer(sampleBuffer),
                let parameterSets = self.parameterSets,
                self.rtspServer != nil && status == noErr {
                
                let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                let dataArray = bb.NALUnits(headerLength: Int(parameterSets.NALHeaderLength))
                
                _ = self.bpsMeter.measure(dataArray: dataArray, pts: pts)

                self.rtspServer?.bitrate = Int32(self.bpsMeter.bps)
                self.rtspServer?.onVideoData(dataArray, time: pts)
            }
        }
        
        encoder.onParameterSets = { parameterSets in
            if parameterSets.avcC != nil {
                self.rtspServer = RTSPServer.setupListener(parameterSets.avcC as Data!)
            }
            self.parameterSets = parameterSets
        }
        return encoder
    }()
    
    init(preferredBitrate: Int) {
        self.preferredBitrate = preferredBitrate
    }
    
    func add(sampleBuffer: CMSampleBuffer!) {
        encoder.encode(sampleBuffer: sampleBuffer)
    }
    
    func stop() {
        encoder.close()
        rtspServer?.shutdownServer()
    }

}

extension CMBlockBuffer {
    
    /*
     * List of NAL Units without NALUnitHeader
     */
    func NALUnits(headerLength: Int) -> [Data] {
        var totalLength: Int = 0
        var pointer:UnsafeMutablePointer<Int8>? = nil
        var dataArray: [Data] = []
        
        if noErr == CMBlockBufferGetDataPointer(self, 0, &totalLength, nil, &pointer) {
            while totalLength > Int(headerLength) {
                let unitLength = pointer!.withMemoryRebound(to: UInt8.self, capacity: totalLength) {
                    NALUtil.readNALUnitLength(at: $0, headerLength: Int(headerLength))
                }
                
                dataArray.append(Data(bytesNoCopy: pointer!.advanced(by: Int(headerLength)),
                                      count: unitLength,
                                      deallocator: .none))
                
                let nextOffset = headerLength + unitLength
                pointer = pointer!.advanced(by: nextOffset)
                totalLength -= Int(nextOffset)
            }
        }
        
        return dataArray
    }
    
}

