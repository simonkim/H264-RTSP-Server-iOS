Hardware Video Encoding on iPhone — RTSP Server example

This is an unofficial mirror of the great work by the guys at GDCL: http://www.gdcl.co.uk/2013/02/20/iOS-Video-Encoding.html

# Use of Video Toolbox
Based on the original work at GDCL, hardware encoding part has been rewritten using iOS Video Toolbox. See VTEncoder.swift for the related implementation.

## VTEncoderVideoStreamer.swift
To adapt the new VTEncoder.swift with CameraServer and RTSPServer, by removing AVEncoder.mm, calls to AVEncoder and RTSPServer has been extracted out to VideoCaptureDelegate.
Then, VTEncoderVideoStreamer.swift 
1. Conforms to VideoCaptureDelegate
2. Calls VTEncoder and RTSPServer to encode and stream
3. Injected to CameraServer to be called whenever necessary

## iOS 9
Although Video Toolbox was first introduced in iOS 8, this implementation is compatible with iOS 9 or later due to the API used for simplicity of usage:

```
VTCompressionSessionEncodeFrameWithOutputHandler(
    session,
    imageBuffer!,
    timingInfo.presentationTimeStamp,
    timingInfo.duration,
    frameProperties,
    &infoFlags,
    encoded)

...
private func encoded(status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) {
    // ...
}
```
that support context capturing closuer as encoded frame output callback.

## Use of Swift 3
Most of newly added files are written in Swift 3 and requires Xcode 8 GM seed to build, as of today.
