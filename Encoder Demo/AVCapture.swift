//
//  AVCapture.swift
//  Encoder Demo
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016년 Geraint Davies. All rights reserved.
//

import Foundation


protocol CaptureImplementation {
    func configure(with session:AVCaptureSession)
    func stop()
    func reset(with session:AVCaptureSession)
}

class AVCapture: CaptureServiceDelegate {
    
    var audioCapture = AudioCapture()
    var videoCapture = VideoCapture()
    
    func captureService(_ service: CameraServer!, configureSession session: AVCaptureSession!) {
        audioCapture.configure(with:session)
        videoCapture.configure(with:session)
    }
    
    func captureService(_ service: CameraServer!, resetSessionForReconfigure session: AVCaptureSession!) {
        audioCapture.reset(with:session)
        videoCapture.reset(with:session)
    }
    
    func captureServiceDidStop(_ service: CameraServer!) {
        audioCapture.stop()
        videoCapture.stop()
    }
}
