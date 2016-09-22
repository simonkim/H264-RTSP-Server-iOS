//
//  PreviewController.swift
//  Encoder Demo
//
//  Created by Simon Kim on 9/22/16.
//  Copyright © 2016 Geraint Davies. All rights reserved.
//

import UIKit

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
    
    
    private var captureServiceDelegate = AVCapture()
    private var cameraServer: CameraServer {
        return CameraServer.server()
    }
    
    private var currentPreset: Preset = .H720p1Mbps
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        let layer = CameraServer.server().getPreviewLayer()!
        layer.frame = cameraView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
        let layer = CameraServer.server().getPreviewLayer()!
        layer.connection.videoOrientation = .portrait
    }
    
    func startPreview() {
        let layer = CameraServer.server().getPreviewLayer()!
        layer.removeFromSuperlayer()
        layer.connection.videoOrientation = .portrait
        
        cameraView.layer.addSublayer(layer)
        
        serverAddress.text = CameraServer.server().getURL()
    }
    
    func changeResolution(preset: Preset) {
        captureServiceDelegate.videoCapture.preferredSessionPreset = preset.videoPreset()
        captureServiceDelegate.videoCapture.preferredBitrate = preset.bitrate()
        cameraServer.reconfigure()
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
            cameraServer.delegate = captureServiceDelegate
            cameraServer.startup()
            startPreview()
        } else {
            // background
            cameraServer.shutdown()
        }
    }
}
