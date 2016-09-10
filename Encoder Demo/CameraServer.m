//
//  CameraServer.m
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "CameraServer.h"
#import "AVEncoder.h"
#import "RTSPServer.h"

static CameraServer* theServer;

@interface CameraServer  () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession* _session;
    AVCaptureVideoPreviewLayer* _preview;
    AVCaptureVideoDataOutput* _output;
    dispatch_queue_t _captureQueue;
    
}
@property (nonatomic) NSString *captureSessionPreset;
@property (nonatomic) CGSize videoSize;
@property (nonatomic) AVCaptureDevicePosition captureDevicePosition;
@end


@implementation CameraServer

+ (void) initialize
{
    // test recommended to avoid duplicate init via subclass
    if (self == [CameraServer class])
    {
        theServer = [[CameraServer alloc] init];
    }
}

+ (CameraServer*) server
{
    return theServer;
}

- (id) init
{
    if ( self = [super init]) {
        self.captureSessionPreset = AVCaptureSessionPreset1920x1080;
        self.captureDevicePosition = AVCaptureDevicePositionBack;
    }
    return self;
}

- (void) setCaptureSessionPreset:(NSString *)captureSessionPreset
{
    CGSize videoSize = CGSizeMake(640, 480);
    
    if (captureSessionPreset == AVCaptureSessionPreset640x480) {
        videoSize = CGSizeMake(640, 480);
    } else if (captureSessionPreset == AVCaptureSessionPreset1920x1080) {
        videoSize = CGSizeMake(1920, 1080);
    } else {
        captureSessionPreset = AVCaptureSessionPreset1280x720;
        videoSize = CGSizeMake(1280, 720);
    }
    _captureSessionPreset = captureSessionPreset;
    self.videoSize = videoSize;
}

- (AVCaptureDevice *) captureDevice
{
    AVCaptureDevice* __block result = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    [devices enumerateObjectsUsingBlock:^(AVCaptureDevice *  _Nonnull device, NSUInteger idx, BOOL * _Nonnull stop) {
        if (device.position == self.captureDevicePosition) {
            result = device;
            *stop = YES;
        }
    }];
    
    return result;
}

- (void) startup
{
    if (_session == nil)
    {
        NSLog(@"Starting up server");
        
        // create capture device with video input
        _session = [[AVCaptureSession alloc] init];
        [_session beginConfiguration];
        
        AVCaptureDevice* dev = [self captureDevice];
        AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:dev error:nil];
        [_session addInput:input];
        
        // create an output for YUV output with self as delegate
        _captureQueue = dispatch_queue_create("uk.co.gdcl.avencoder.capture", DISPATCH_QUEUE_SERIAL);
        _output = [[AVCaptureVideoDataOutput alloc] init];
        [_output setSampleBufferDelegate:self queue:_captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _output.videoSettings = setcapSettings;
        [_session addOutput:_output];
        
        // create an encoder
        [self.delegate cameraServer:self willBeginCaptureWithSize:self.videoSize];
        
        _session.sessionPreset = self.captureSessionPreset;
        [_session commitConfiguration];
        // start capture and a preview layer
        [_session startRunning];
        
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // pass frame to encoder
    [self.delegate cameraServer:self didCapture:sampleBuffer];
}

- (void) shutdown
{
    NSLog(@"shutting down server");
    if (_session)
    {
        [_session stopRunning];
        _session = nil;
    }
    [self.delegate cameraServerDidStop:self];
    
}

- (NSString*) getURL
{
    NSString* ipaddr = [RTSPServer getIPAddress];
    NSString* url = [NSString stringWithFormat:@"rtsp://%@/", ipaddr];
    return url;
}

- (AVCaptureVideoPreviewLayer*) getPreviewLayer
{
    return _preview;
}

@end
