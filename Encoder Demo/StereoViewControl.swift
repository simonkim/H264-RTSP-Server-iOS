//
//  StereoViewControl.swift
//  Encoder Demo
//
//  Created by Simon Kim on 10/5/16.
//  Copyright © 2016 Geraint Davies. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class StereoViewControl {
    var enabled: Bool = false {
        willSet(newValue) {
            setStereoView(enabled: newValue)
        }
    }
    
    var capturePreviewLayer: AVCaptureVideoPreviewLayer? = nil
    var leftPOV: UIView
    var rightPOV: UIView
    var masterClock: CMClock
    
    fileprivate var rightPOVLayer: AVSampleBufferDisplayLayer? = nil
    
    init(previewLayer: AVCaptureVideoPreviewLayer,
         leftPOV: UIView,
         rightPOV: UIView,
         masterClock: CMClock)
    {
        
        capturePreviewLayer = previewLayer
        self.leftPOV = leftPOV
        self.rightPOV = rightPOV
        self.masterClock = masterClock
    }
    
    func createSampleBufferDisplayLayer(rect: CGRect) -> AVSampleBufferDisplayLayer {
        
        let layer = AVSampleBufferDisplayLayer()
        layer.bounds = rect
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        return layer
    }
    
    func updatePreviewLayout() {
        capturePreviewLayer?.frame = leftPOV.bounds
        rightPOVLayer?.frame = rightPOV.bounds
    }
    
    func setStereoView(enabled: Bool) {
        
        guard let previewLayer = capturePreviewLayer else {
            return
        }
        if self.enabled == enabled {
            return
        }
        
        if enabled {
            let superlayer = leftPOV.layer
            
            if rightPOVLayer == nil {
                let rightLayer = createSampleBufferDisplayLayer(rect: rightPOV.bounds)
                rightPOV.layer.addSublayer(rightLayer)
                var timebase: CMTimebase?
                CMTimebaseCreateWithMasterClock(kCFAllocatorDefault, masterClock, &timebase)
                if let timebase = timebase {
                    CMTimebaseSetRate(timebase, 1.0)
                    CMTimebaseSetTime(timebase, CMClockGetTime(masterClock))
                    rightLayer.controlTimebase = timebase
                }
                self.rightPOVLayer = rightLayer
            }
            previewLayer.removeFromSuperlayer()
            superlayer.addSublayer(previewLayer)
        }
        leftPOV.isHidden = !enabled
        rightPOV.isHidden = !enabled
        updatePreviewLayout()
    }
    
    func enqueue(_ sbuf: CMSampleBuffer) {
        self.rightPOVLayer?.enqueue(sbuf)
        
    }
}
