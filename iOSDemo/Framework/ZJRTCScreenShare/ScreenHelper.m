//
//  ScreenHelper.m
//  ZJScreenShare
//
//  Created by starcwl on 12/3/18.
//  Copyright © 2018 zijingcloud. All rights reserved.
//

#import <WebRTC/WebRTC.h>
#import "ScreenHelper.h"
#import "SdpTransformer.h"
#import "ARDExternalSampleCapturer.h"

typedef NS_ENUM(NSUInteger, ZJSystemState) {
    ZJSystemStateIdle,
    ZJSystemStateConnected
};

static NSString * const kScreenStreamId = @"screenShareStream";
static NSString * const kScreenShareTrackId = @"screenShareTrack";
static int const kKbpsMultiplier = 1000;

@interface ScreenHelper ()
@property(nonatomic, strong) RTCPeerConnectionFactory *pcFactory;
@property(nonatomic, strong) RTCPeerConnection *pc;
@property(atomic, assign) ZJSystemState state;
@property (nonatomic, strong) RTCVideoTrack *localVideoTrack;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSString *p_call_id ;
@property (nonatomic, strong) NSString *cUuid;
@property (nonatomic, strong) NSString *pUuid;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *mcuServer;
@property (nonatomic, strong) NSString *channel;
@property(nonatomic, assign) BOOL isBroadcast;
@property (nonatomic, strong) ARDExternalSampleCapturer *capturer;
@property (nonatomic, assign) int fps;

@end

@implementation ScreenHelper
+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isBroadcast = true;
        RTCDefaultVideoDecoderFactory *decoderFactory
            = [[RTCDefaultVideoDecoderFactory alloc] init];
        RTCDefaultVideoEncoderFactory *encoderFactory
            = [[RTCDefaultVideoEncoderFactory alloc] init];
//        self.pcFactory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory
//                                                                   decoderFactory:decoderFactory];
        self.pcFactory = [[RTCPeerConnectionFactory alloc] init];
        NSDictionary *optionalConstraints = @{@"DtlsSrtpKeyAgreement": @"false"};
        RTCMediaConstraints *constraints =
            [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil
                                                  optionalConstraints:optionalConstraints];
        RTCConfiguration *config = [[RTCConfiguration alloc] init];
        RTCCertificate *pcert = [RTCCertificate generateCertificateWithParams:@{
            @"expires" : @100000,
            @"name" : @"RSASSA-PKCS1-v1_5"
        }];
//        config.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
//        config.certificate = pcert;
        
        self.p_call_id = @"";
        self.pc = [self.pcFactory peerConnectionWithConfiguration:config
                                                      constraints:constraints
                                                         delegate:self];
        if ( [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"] ) {
            self.fps = 3;
        }
        else {
            self.fps = 6;
        }
        NSLog(@"[screen] fps set to %d", self.fps);
    }
    return self;
}

- (void)connect{
    self.token = [self.userDefaults objectForKey:@"token"];
    self.pUuid = [self.userDefaults objectForKey:@"pUuid"];
    self.channel = [self.userDefaults objectForKey:@"channel"];
    self.mcuServer = [self.userDefaults objectForKey:@"mcuHost"];
    NSLog(@"[screen] connect info: \nchannel: %@, \nmcuHost: %@, \npUuid: %@, \ntoken: %@",
        self.channel,
        self.mcuServer,
        self.pUuid,
        self.token);

    [self createMediaSenders];
    [self createOffer];
}

- (void)setGroupId:(NSString*)groupId {
    _groupId = groupId;
    self.userDefaults = [[NSUserDefaults alloc]
        initWithSuiteName:_groupId];
}

- (void)disconnect{
    [self makeScreenCallWithParams:@{} open:NO success:^(id response) {
        [self.pc close];
    } failure:^(NSError * error) {
        
    }];
}

- (void)didCaptureSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.capturer didCaptureSampleBuffer:sampleBuffer];
}


- (void)createOffer{
    [self.pc offerForConstraints:[self defaultOfferConstraints]
               completionHandler:^(RTCSessionDescription *sdp, NSError *error) {
        if(error) NSLog(@"[screen] create offer error: %@", [error localizedDescription]);
        else NSLog(@"[screen] Create offer successful");
        [self.pc setLocalDescription:sdp completionHandler:^(NSError *error) {
            if (error){
                NSLog(@"setLocalDescription failure: %@", [error localizedDescription]);
            }
            else {
                NSLog(@"setLocalDescription successful");
                NSLog(@"[screen] origin offer: \n%@", self.pc.localDescription.sdp);
            }
        }];
    }];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
    NSDictionary *mandatoryConstraints = @{
        @"OfferToReceiveAudio" : @"false",
        @"OfferToReceiveVideo" : @"false"
    };
    RTCMediaConstraints* constraints =
        [[RTCMediaConstraints alloc]
            initWithMandatoryConstraints:mandatoryConstraints
                     optionalConstraints:nil];
    return constraints;
}

- (void)createMediaSenders {
  RTCMediaConstraints *constraints = [self defaultMediaAudioConstraints];
//  RTCAudioSource *source = [self.pcFactory audioSourceWithConstraints:constraints];
//  RTCAudioTrack *track = [self.pcFactory audioTrackWithSource:source
//                                                trackId:kARDAudioTrackId];
//  [self.pc addTrack:track streamIds:@[ kARDMediaStreamId ]];
  _localVideoTrack = [self createLocalVideoTrack];
  if (_localVideoTrack) {
    [self.pc addTrack:_localVideoTrack streamIds:@[ kScreenStreamId ]];
  }
}

- (RTCMediaConstraints *)defaultMediaAudioConstraints {
    NSDictionary *mandatoryConstraints = @{};
    RTCMediaConstraints *constraints =
        [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                              optionalConstraints:nil];
    return constraints;
}

- (RTCVideoTrack *)createLocalVideoTrack {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    RTCVideoSource *source = [self.pcFactory videoSource];
    
    [source adaptOutputFormatToWidth:1280 height:720 fps:self.fps];
#if !TARGET_IPHONE_SIMULATOR
    if (self.isBroadcast) {
        self.capturer =
            [[ARDExternalSampleCapturer alloc] initWithDelegate:source];
//        if(capturer && [_delegate respondsToSelector:@selector(appClient:didCreateLocalExternalSampleCapturer:)]){
//            NSLog(@"[screen] capturer prepared.");
//            [_delegate appClient:self didCreateLocalExternalSampleCapturer:capturer];
//        }
    } else {
//        RTCCameraVideoCapturer *capturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:source];
//        [_delegate appClient:self didCreateLocalCapturer:capturer];
    }
#else
    #if defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
  if (@available(iOS 10, *)) {
    RTCFileVideoCapturer *fileCapturer = [[RTCFileVideoCapturer alloc] initWithDelegate:source];
    [_delegate appClient:self didCreateLocalFileCapturer:fileCapturer];
  }
#endif
#endif

    return [self.pcFactory videoTrackWithSource:source trackId:kScreenShareTrackId];
}


- (void) offerCreated{

    RTCSessionDescription *mSdpObj = [[RTCSessionDescription alloc] initWithType:[RTCSessionDescription typeForString:@"offer"]
                                                                             sdp:self.pc.localDescription.sdp];


    [self.pc setLocalDescription:mSdpObj completionHandler:^(NSError *error) {
        if (error) NSLog(@"setLocalDescription failure");
    }];

    NSString *mutateOffer = [[SdpTransformer sharedSdpTransformer] addAttributesForPresentWithSdp:self.pc.localDescription.sdp];
    NSLog(@"[sdp-offer]mutated offer: \n%@", mutateOffer);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"call_type": @"WEBRTC",
        @"sdp": mutateOffer,
        @"present": @"send"
    }];

    NSLog(@" --- e%@",params);

    [self makeScreenCallWithParams:params open:YES success:^(id response) {
        NSLog(@"[screen] calls request successful");
        NSString *answerSdp = response[@"result"][@"sdp"];
        RTCSessionDescription *answerSdpObj = [[RTCSessionDescription alloc] initWithType:[RTCSessionDescription typeForString:@"answer"]
                                                                                      sdp:answerSdp];
        NSLog(@"[screen] orinal answer: \n%@", response);
        self.cUuid = response[@"result"][@"call_uuid"];
        [self.userDefaults setObject:self.cUuid forKey:@"record_screen_call_id"];
        [self.pc setRemoteDescription:answerSdpObj completionHandler:^(NSError *error) {
            if(error){
                NSLog(@"set Remote SDP failed: %@", [error localizedDescription]);
            }else{
                NSLog(@"set Remote SDP successfull");
                [self updateRTPSenderParameter];
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"calls request error: %@", error);
    }];
}

- (void)updateRTPSenderParameter{
    //TODO set bandwidth
    for (RTCRtpSender *sender in _pc.senders) {
        if (sender.track != nil) {
            if ([sender.track.trackId isEqualToString:kScreenShareTrackId]){
                [self setMaxBandwith:@(1200) frameRate:@(self.fps) forSender:sender];
            }
        }
    }
}

- (void)setMaxBandwith:(NSNumber*)bitrate frameRate:(NSNumber*)fps forSender:(RTCRtpSender*)sender{
    RTCRtpParameters *parametersToModify = sender.parameters;
    for (RTCRtpEncodingParameters *encoding in parametersToModify.encodings) {
        encoding.maxBitrateBps = @(bitrate.intValue * kKbpsMultiplier);
        encoding.minBitrateBps = @(bitrate.intValue * kKbpsMultiplier * 0.5);
        encoding.maxFramerate = fps;
    }
    [sender setParameters:parametersToModify];
}

- (BOOL )isValiedIP :(NSString *)serverAddress {
    for (NSString *subAddr in [serverAddress componentsSeparatedByString:@"."]) {
        NSString * newSubAddr = [subAddr stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] ;
        if (newSubAddr.length > 0) {
            return NO;
        }
    }
    return YES ;
}

- (void)makeScreenCallWithParams:(NSDictionary *)params open:(BOOL )open success:(void(^)(id))success failure:(void(^)(NSError*))failure {
    NSError *error;
    
    BOOL isValied = [self isValiedIP: _mcuServer];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/api/services/%@/participants/%@/calls",
                                                                 isValied ? @"http" : @"https",
                                                                 _mcuServer,
                                                                 _channel,
                                                                 _pUuid]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:_token forHTTPHeaderField:@"token"];
    [request setHTTPMethod:@"POST"];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    [request setHTTPBody:postData];

    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(!error){
            if(success) success([NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);
            NSLog(@"请求成功 -- %@", data);
        } else {
            if(failure) failure(error);
            NSLog(@"请求失败 -- %@", error);
        }
    }];

    [postDataTask resume];

}


- (void)ackConnectSuccess:(void(^)(id))success failure:(void(^)(NSError*))failure {
    BOOL isValied = [self isValiedIP: self.mcuServer];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/api/services/%@/participants/%@/calls/%@/ack",isValied ? @"http" : @"https" ,
                                      self.mcuServer, _channel, _pUuid, _cUuid]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:_token forHTTPHeaderField:@"token"];
    [request setHTTPMethod:@"POST"];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(!error){
            if(success) success([NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);
            NSLog(@"请求成功 -- %@", data);
        }
        else {
            if(failure) failure(error);
            NSLog(@"请求失败 -- %@", error);
        }
    }];
    [postDataTask resume];
}

#pragma mark - RTCPeerConnectionDelegate

/** Called when the SignalingState changed. */
- (void) peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged; {

}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream;{
}

/** Called when a remote peer closes a stream.
 *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream{

}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection;{

}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState{

}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState{
    if (newState == RTCIceGatheringStateComplete) {
        [self offerCreated];
    }
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate{

}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates{

}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel{

}

/** Called when signaling indicates a transceiver will be receiving media from
 *  the remote endpoint.
 *  This is only called with RTCSdpSemanticsUnifiedPlan specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didStartReceivingOnTransceiver:(RTCRtpTransceiver *)transceiver{

}

/** Called when a receiver and its track are created. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
        didAddReceiver:(RTCRtpReceiver *)rtpReceiver
               streams:(NSArray<RTCMediaStream *> *)mediaStreams{

}


@end
