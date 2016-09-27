//
//  PreviewController.swift
//  Encoder Demo
//
//  Created by Simon Kim on 9/22/16.
//  Copyright © 2016 Geraint Davies. All rights reserved.
//

import UIKit
import AVFoundation
import AVCapture

class PreviewController: UIViewController {
    
    enum Preset: Int {
        case H480p512Kbps = 0
        case H720p1Mbps = 1
        case H1080p2Mbps = 2
        
        static let bitrates: [Int] = [
            512 * 1024,
            1024 * 1024,
            2048 * 1024
        ]
        
        static let videoPresets: [String] = [
            AVCaptureSessionPreset640x480,
            AVCaptureSessionPreset1280x720,
            AVCaptureSessionPreset1920x1080
        ]
        
        func videoPreset() -> String {

            return Preset.videoPresets[self.rawValue]
        }
        
        func bitrate() -> Int {
            return Preset.bitrates[self.rawValue]
        }
    }
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var serverAddress: UILabel!
    @IBOutlet var resolutionSlider: UISlider!
    
    
    private var captureClient = AVCaptureClientSimple()
    lazy private var captureService: AVCaptureService = {
        return AVCaptureService(client: self.captureClient)
    }()
    
    private var currentPreset: Preset = .H720p1Mbps
    fileprivate var rtspServer: RTSPServer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureClient.dataDelegate = self
    }
    
    override func viewDidLayoutSubviews() {
        let layer = captureService.previewLayer
        layer?.frame = cameraView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
        let layer = captureService.previewLayer
        layer?.connection.videoOrientation = toInterfaceOrientation.videoOrientation
    }
    
    func startPreview() {
        if let layer = captureService.previewLayer {
            layer.removeFromSuperlayer()
            layer.connection.videoOrientation = .portrait
            
            cameraView.layer.addSublayer(layer)
        }
        
        serverAddress.text = "rtsp://\(RTSPServer.getIPAddress())/"
    }
    
    func changeResolution(preset: Preset) {
        captureClient.videoCapture.set(value: preset.videoPreset(), forKey: .AVCaptureSessionPreset)
        captureClient.videoCapture.set(value: preset.bitrate(), forKey: .bitrate)
        
        captureService.reconfigure()
    }
    
    // MARK: Actions
    @IBAction func resolutionSliderTouchUp(_ sender: UISlider) {
        sender.value = roundf(sender.value)

        if let preset = Preset(rawValue: Int(sender.value)), currentPreset != preset {
            DispatchQueue.global().async {
                self.changeResolution(preset: preset)
            }
            currentPreset = preset
        }
    }
    
    // MARK: API
    func change(activeState: Bool) {
        if activeState {
            // foreground from background
            _ = captureService.start()
            startPreview()
        } else {
            // background
            captureService.stop()
        }
    }
    
    // MARK: AVCaptureClientDataDelegate
    var paramSets: H264ParameterSets? = nil
    var bpsMeter: BitrateMeasure = BitrateMeasure()
    
}

extension PreviewController: AVCaptureClientDataDelegate {

    private func paramSets(from sampleBuffer:CMSampleBuffer) -> H264ParameterSets?
    {
        var result: H264ParameterSets? = nil
        if let formatDescription = sampleBuffer.formatDescription {
            if formatDescription.mediaSubType == kCMVideoCodecType_H264 {
                result = H264ParameterSets(withFormatDescription: formatDescription)
            }
        }
        return result
    }
    
    func client(client: AVCaptureClient, output sampleBuffer: CMSampleBuffer )
    {
        if client.mediaType == kCMMediaType_Video {
            if paramSets == nil {
                if let ps = paramSets(from: sampleBuffer) {
                    paramSets = ps
                    self.rtspServer = RTSPServer.setupListener(ps.avcC as Data!)
                }
            }
            output(videoSample: sampleBuffer)
        } else if client.mediaType == kCMMediaType_Audio {
            output(audioSample: sampleBuffer)
        }
    }
    
    public func client(client: AVCaptureClient, didConfigureVideoSize videoSize: CGSize) {
        if let rtspServer = rtspServer {
            rtspServer.shutdownServer()
            self.rtspServer = nil
            self.paramSets = nil
            self.bpsMeter = BitrateMeasure()
        }
    }
    
    
    func output(videoSample sampleBuffer: CMSampleBuffer)
    {
        guard let paramSets = paramSets else {
            return
        }
        
        if let bb = CMSampleBufferGetDataBuffer(sampleBuffer),
            let rtspServer = rtspServer {
            
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            let dataArray = bb.NALUnits(headerLength: Int(paramSets.NALHeaderLength))
            
            _ = self.bpsMeter.measure(dataArray: dataArray, pts: pts)
            
            rtspServer.bitrate = Int32(self.bpsMeter.bps)
            rtspServer.onVideoData(dataArray, time: pts)
        }
    }
    
    func output(audioSample sampleBuffer: CMSampleBuffer)
    {
        // audio samples
    }
}


extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation
    {
        var result: AVCaptureVideoOrientation = .landscapeLeft
        
        switch(self) {
        case .portrait:
            result = .portrait
            break
            
        case .portraitUpsideDown:
            result = .portraitUpsideDown
            break
            
        case .landscapeLeft:
            result = .landscapeLeft
            break
            
        case .landscapeRight:
            result = .landscapeRight
            break
        default:
            break
        }
        
        return result
    }
}
