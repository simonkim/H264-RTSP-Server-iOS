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

        static let videoDimensionsList: [CMVideoDimensions] = [
            CMVideoDimensions(width: 640, height: 480),
            CMVideoDimensions(width: 1280, height: 720),
            CMVideoDimensions(width: 1920, height: 1080),
        ]
        
        static let frameRates: [Float64] = [
            60,
            60,
            60,
        ]
        
        var bitrate: Int {
            return Preset.bitrates[self.rawValue]
        }
        
        var videoDimensions: CMVideoDimensions {
            return Preset.videoDimensionsList[self.rawValue]
        }
        var frameRate: Float64 {
            return Preset.frameRates[self.rawValue]
        }
        
        var captureClientOptions: [AVCaptureClientOptionKey] {
            return [
                .videoDimensions(videoDimensions),
                .videoFrameRate(frameRate),
                .videoBitrate(bitrate),
                .encodeVideo(false)
            ]
        }
    }
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var serverAddress: UILabel!
    @IBOutlet var resolutionSlider: UISlider!
    @IBOutlet var controlView: UIView!
    @IBOutlet var labelVideoFormat: UILabel!

    @IBOutlet var leftPOV: UIView!
    @IBOutlet var rightPOV: UIView!
    
    fileprivate var stereoViewEnabled = false
    fileprivate var rightPOVLayer: AVSampleBufferDisplayLayer? = nil
    
    private var captureClient = AVCaptureClientSimple()
    lazy fileprivate var captureService: AVCaptureService = {
        return AVCaptureService(client: self.captureClient)
    }()
    
    fileprivate var currentPreset: Preset = .H720p1Mbps
    fileprivate var rtspServer: RTSPServer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureClient.dataDelegate = self
        captureClient.options = currentPreset.captureClientOptions
        
        var gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        view.addGestureRecognizer(gesture)
        
        gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        controlView.addGestureRecognizer(gesture)
    }
    
    override func viewDidLayoutSubviews() {
        updatePreviewLayout(stereoView: stereoViewEnabled)
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
        let layer = captureService.previewLayer
        layer?.connection.videoOrientation = toInterfaceOrientation.videoOrientation
    }
    
    func startPreview() {
        
        if let previewLayer = captureService.previewLayer {
            cameraView.layer.addSublayer(previewLayer)
        }
        serverAddress.text = "rtsp://\(RTSPServer.getIPAddress())/"
    }
    
    func changeResolution(preset: Preset) {
        captureClient.options = preset.captureClientOptions
        captureService.reconfigure()
    }
    
    func updatePreviewLayout() {
        let layer = captureService.previewLayer
        layer?.frame = cameraView.bounds
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

    // MARK: Gesture
    func didTap(_ gestureRecognizer: UITapGestureRecognizer)
    {
        if gestureRecognizer.view == self.view {
            controlView.isHidden = false
        } else if gestureRecognizer.view == controlView {
            controlView.isHidden = true
        }
    }
    
    @IBAction func toggleStereoView(_ sender: UISwitch) {
        
        setStereoView(enabled: sender.isOn)
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
    
    var videoEncoder: VTEncoder? = nil
    
    let skipVideoEncodingEvery: Int = 1
    var skipCounter: Int = 0
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
            if skipCounter == 0 {
                videoEncoder?.encode(sampleBuffer: sampleBuffer)
                skipCounter = skipVideoEncodingEvery
            } else {
                skipCounter -= 1
            }
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
        
        self.videoEncoder?.close()
        skipCounter = 0
        
        let encoder = VTEncoder(width: Int32(videoSize.width), height: Int32(videoSize.height), bitrate: currentPreset.bitrate)
        encoder.onEncoded = { status, infoFlags, sampleBuffer in
            if let sampleBuffer = sampleBuffer, status == noErr {
                if self.paramSets == nil {
                    if let ps = self.paramSets(from: sampleBuffer) {
                        self.paramSets = ps
                        self.rtspServer = RTSPServer.setupListener(ps.avcC as Data!)
                    }
                }
                self.output(videoSample: sampleBuffer)
            }
        }
        self.videoEncoder = encoder
        
        DispatchQueue.main.async {
            self.labelVideoFormat.text = String(format:"%dx%d", Int(videoSize.width), Int(videoSize.height))
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

// MARK: Stereo View
extension PreviewController {
    func createSampleBufferDisplayLayer(rect: CGRect) -> AVSampleBufferDisplayLayer {
        
        let layer = AVSampleBufferDisplayLayer()
        layer.bounds = rect
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        return layer
    }
    
    func updatePreviewLayout(stereoView: Bool) {
        
        if stereoView {
            captureService.previewLayer?.frame = leftPOV.bounds
            rightPOVLayer?.frame = rightPOV.bounds
        } else {
            updatePreviewLayout()
        }
    }
    
    func setStereoView(enabled: Bool) {
        
        guard let previewLayer = captureService.previewLayer else {
            return
        }
        if stereoViewEnabled == enabled {
            return
        }
        
        let superlayer: CALayer
        if enabled {
            superlayer = leftPOV.layer
            
            if rightPOVLayer == nil {
                let rightLayer = createSampleBufferDisplayLayer(rect: rightPOV.bounds)
                rightPOV.layer.addSublayer(rightLayer)
                var timebase: CMTimebase?
                CMTimebaseCreateWithMasterClock(kCFAllocatorDefault, captureService.masterClock, &timebase)
                if let timebase = timebase {
                    CMTimebaseSetRate(timebase, 1.0)
                    CMTimebaseSetTime(timebase, CMClockGetTime(captureService.masterClock))
                    rightLayer.controlTimebase = timebase
                }
                self.rightPOVLayer = rightLayer
            }
        } else {
            superlayer = cameraView.layer
        }
        leftPOV.isHidden = !enabled
        rightPOV.isHidden = !enabled
        
        previewLayer.removeFromSuperlayer()
        superlayer.addSublayer(previewLayer)
        
        stereoViewEnabled = enabled
        updatePreviewLayout(stereoView: stereoViewEnabled)
    }
}
