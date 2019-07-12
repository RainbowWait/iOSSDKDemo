//
//  SdpTransformer.h
//  webrtc-iOS-demo
//
//  Created by starcwl on 10/17/18.
//  Copyright © 2018 zijingcloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


extern NSString * const CODEC_VP9;
extern NSString * const CODEC_VP8;
extern NSString * const CODEC_H264_BASE;
extern NSString * const CODEC_H264_PROFILE;

@interface SdpTransformer : NSObject

@property (nonatomic, strong) NSString *vp8Sdp;
@property (nonatomic, strong) NSString *vp8SdpRtx;
@property (nonatomic, strong) NSString *vp9Sdp;
@property (nonatomic, strong) NSString *vp9SdpRtx;
@property (nonatomic, strong) NSString *ulpfecSdp;
@property (nonatomic, strong) NSString *redSdp;
@property (nonatomic, strong) NSString *redSdpRtx;

@property (nonatomic, strong) NSString *h264BaseSdpRtx;
@property (nonatomic, strong) NSString *h264ProfileSdpRtx;

@property (nonatomic, strong) NSSet *videoCodecsFilter;
@property (nonatomic, strong) NSString *h264BaseId;
@property (nonatomic, strong) NSString *h264ProfileId;

+ (instancetype)sharedSdpTransformer;
- (instancetype)init;

- (NSString *)createH264Sdp:(NSString *)payload id:(NSString *)id;

- (BOOL)isSupportCodec:(NSString *)sdp codec:(NSString *)codec;

- (NSSet *)supportVideoCodecs:(NSString *)sdp;

- (NSString *)uniformOfferSDPCodecsPayload:(NSString *)sdp codecs:(NSArray *)codecs;

- (NSString *)addAttributesForPresentWithSdp:(NSString *)sdp;

- (NSString *)updatePayload:(NSString *)sdp deviceCodecs:(NSArray *)codecs;

- (NSString *)modifySsrcValueWithSdp:(NSString *)sdp;

- (NSString *)useCryptoMethodWithSdp:(NSString *)sdp;

- (NSString *)rearrangeAnswerPayloadOrder:(NSString *)sdp codecs:(NSArray *)codecs;

- (NSString *)adjustStreamsWithSdp:(NSString *)sdp
                            remove:(NSSet *)remove
                               add:(NSSet *)add
                            rtxMap:(NSDictionary *)rtxMap
                            finish:(void (^)(NSDictionary *))finish;
@end

NS_ASSUME_NONNULL_END
