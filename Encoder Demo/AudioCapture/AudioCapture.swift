//
//  AudioCapture.swift
//  Encoder Demo
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016년 Geraint Davies. All rights reserved.
//

import Foundation

class AudioCapture: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, CaptureImplementation {
    
    static var captureQueue: DispatchQueue = {
        return DispatchQueue(label:"audio-capture")
    }()
    
    func configure(with session: AVCaptureSession) {
        
        if let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio),
            devices.count > 0 {
            do {
                let input = try AVCaptureDeviceInput(device: devices[0] as! AVCaptureDevice)
                session.addInput(input)
                
                let output = AVCaptureAudioDataOutput()
                output.setSampleBufferDelegate(self, queue: AudioCapture.captureQueue)
                session.addOutput(output)
            
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    internal func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        print(sampleBuffer)
    }
    
    func stop() {
        
    }
}
