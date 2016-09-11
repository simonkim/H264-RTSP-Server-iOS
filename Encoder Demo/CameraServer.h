//
//  CameraServer.h
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import <Foundation/Foundation.h>
#import "AVFoundation/AVCaptureSession.h"
#import "AVFoundation/AVCaptureOutput.h"
#import "AVFoundation/AVCaptureDevice.h"
#import "AVFoundation/AVCaptureInput.h"
#import "AVFoundation/AVCaptureVideoPreviewLayer.h"
#import "AVFoundation/AVMediaFormat.h"

@class CameraServer;

@protocol CaptureServiceDelegate
- (void) captureService:(CameraServer *) service configureSession:(AVCaptureSession *) session;
- (void) captureServiceDidStop:(CameraServer *) service;
@end

@interface CameraServer : NSObject
@property (nonatomic, weak) id<CaptureServiceDelegate> delegate;

+ (CameraServer*) server NS_SWIFT_NAME(server());
- (void) startup;
- (void) shutdown;
- (NSString*) getURL;
- (AVCaptureVideoPreviewLayer*) getPreviewLayer;

@end
