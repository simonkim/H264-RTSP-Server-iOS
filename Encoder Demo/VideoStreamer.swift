//
//  VideoStreamer.swift
//  Encoder Demo
//
//  Created by Simon Kim on 2016. 9. 10..
//  Copyright © 2016년 Geraint Davies. All rights reserved.
//

import Foundation

class VideoStreamer: VideoCaptureDelegate {
    var rtspServer: RTSPServer?
    
    var videoSize: CGSize = CGSize()
    
    lazy var encoder: AVEncoder = {
        let encoder = AVEncoder(forHeight:Int32(self.videoSize.height), andWidth: Int32(self.videoSize.width))!
        
        encoder.encode(
            { dataArray, pts in
                if self.rtspServer != nil {
                    self.rtspServer!.bitrate = encoder.bitspersecond
                    self.rtspServer!.onVideoData(dataArray, time:pts)
                    print("bitrate:\(encoder.bitspersecond)")
                }
                return 0
            }, onParams:{ avcC in
                self.rtspServer = RTSPServer.setupListener(avcC)
                return 0
        })
        
        return encoder
    }()
    
    func cameraServer(_ server: CameraServer!, willBeginCaptureWith size: CGSize) {
        self.videoSize = size
    }
    
    func cameraServer(_ server: CameraServer!, didCapture sampleBuffer: CMSampleBuffer!) {
        encoder.encodeFrame(sampleBuffer)
    }
    
    func cameraServerDidStop(_ server: CameraServer!) {
        rtspServer?.shutdownServer()
        encoder.shutdown()
    }
}
