//
//  VideoCapture.swift
//  Encoder Demo
//
//  Created by Simon Kim on 2016. 9. 11..
//  Copyright © 2016년 Geraint Davies. All rights reserved.
//

import Foundation

class VideoCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, CaptureImplementation {
    
    var preferredDevicePosition = AVCaptureDevicePosition.back
    var preferredSessionPreset = AVCaptureSessionPreset1280x720
    var preferredBitrate: Int = 1024 * 1024
    var videoStreamer: VTEncoderVideoStreamer
    var videoSize = CGSize(width: 1920, height: 1080)
    
    private static var captureQueue: DispatchQueue = {
        return DispatchQueue(label:"video-capture")
    }()
    
    private var input: AVCaptureDeviceInput? = nil
    private var output: AVCaptureVideoDataOutput? = nil
    
    override init() {
        videoStreamer = VTEncoderVideoStreamer(preferredBitrate: preferredBitrate)
    }
    
    func configure(with session:AVCaptureSession) {
        
        if let device = captureDevice(with: preferredDevicePosition) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                session.addInput(input)
                
                session.sessionPreset = self.preferredSessionPreset
                
                let output = AVCaptureVideoDataOutput()
                
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as AnyHashable:
                        NSNumber(value:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                ]
                session.addOutput(output)
                
                if let width = output.videoSettings["Width"] as? Int,
                    let height = output.videoSettings["Height"] as? Int {
                    videoSize = CGSize(width: width, height: height)
                }

                videoStreamer.videoSize = videoSize
                
                output.setSampleBufferDelegate(self, queue: VideoCapture.captureQueue)

                self.input = input
                self.output = output
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    func reset(with session:AVCaptureSession)
    {
        session.removeOutput(output)
        session.removeInput(input)
        videoStreamer.stop()
        videoStreamer = VTEncoderVideoStreamer(preferredBitrate: preferredBitrate)
    }
    
    func stop() {
        videoStreamer.stop()
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    internal func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        videoStreamer.add(sampleBuffer: sampleBuffer)
    }

    private func captureDevice(with position:AVCaptureDevicePosition) -> AVCaptureDevice? {
        var device: AVCaptureDevice? = nil
        
        if let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            
            for d in devices {
                if (d as! AVCaptureDevice).position == position {
                    device = d as? AVCaptureDevice
                    break
                }
            }
        }
        return device
    }
    
}
