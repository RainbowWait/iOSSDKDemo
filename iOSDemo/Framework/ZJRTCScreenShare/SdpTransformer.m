//
//  SdpTransformer.m
//  webrtc-iOS-demo
//
//  Created by starcwl on 10/17/18.
//  Copyright © 2018 zijingcloud. All rights reserved.
//

#import "SdpTransformer.h"

#define RTX_ENABLED TRUE
#define RED_ENABLED TRUE
#define ULPFED_ENABLED TRUE


NSString * const VP8 = @"96";
NSString * const VP8_RTX = @"107";
NSString * const VP9 = @"98";
NSString * const VP9_RTX = @"108";
NSString * const H264_PROFILE = @"99";
NSString * const H264_PROFILE_RTX = @"111";
NSString * const H264_BASE = @"100";
NSString * const H264_BASE_RTX = @"110";
NSString * const RED = @"106";
NSString * const RED_RTX = @"109";
NSString * const ULPFEC = @"124";

NSString * const CODEC_VP9 = @"VP9";
NSString * const CODEC_VP8 = @"VP8";
NSString * const CODEC_H264_BASE = @"H264_BASE";
NSString * const CODEC_H264_PROFILE = @"H264_PROFILE";

@interface SdpTransformer ()
@end

@implementation SdpTransformer
+ (instancetype)sharedSdpTransformer {
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
        self.vp8Sdp = [NSString stringWithFormat:@"a=rtpmap:%@ VP8/90000\r\n"
                                                 "a=rtcp-fb:%@ ccm fir\r\n"
                                                 "a=rtcp-fb:%@ nack\r\n"
                                                 "a=rtcp-fb:%@ nack pli\r\n"
                                                 "a=rtcp-fb:%@ goog-remb\r\n"
                                                 "a=rtcp-fb:%@ transport-cc\r\n", VP8, VP8, VP8, VP8, VP8, VP8];

        self.vp8SdpRtx = [NSString stringWithFormat:@"a=rtpmap:%@ rtx/90000\r\n"
                                                    "a=fmtp:%@ apt=%@\r\n", VP8_RTX, VP8_RTX, VP8];

        self.vp9Sdp = [NSString stringWithFormat:@"a=rtpmap:%@ VP9/90000\r\n"
                                                 "a=rtcp-fb:%@ ccm fir\r\n"
                                                 "a=rtcp-fb:%@ nack\r\n"
                                                 "a=rtcp-fb:%@ nack pli\r\n"
                                                 "a=rtcp-fb:%@ goog-remb\r\n"
                                                 "a=rtcp-fb:%@ transport-cc\r\n", VP9, VP9, VP9, VP9, VP9, VP9];

        self.vp9SdpRtx = [NSString stringWithFormat:@"a=rtpmap:%@ rtx/90000\r\n"
                                                    "a=fmtp:%@ apt=%@\r\n", VP9_RTX, VP9_RTX, VP9];


        self.ulpfecSdp = [NSString stringWithFormat:@"a=rtpmap:%@ ulpfec/90000\r\n", ULPFEC];

        self.redSdp = [NSString stringWithFormat:@"a=rtpmap:%@ red/90000\r\n", RED];

        self.redSdpRtx = [NSString stringWithFormat:@"a=rtpmap:%@ rtx/90000\r\n"
                                                    "a=fmtp:%@ apt=%@\r\n", RED_RTX, RED_RTX, RED];

        self.h264BaseSdpRtx = [NSString stringWithFormat:@"a=rtpmap:%@ rtx/90000\r\n"
                                                         "a=fmtp:%@ apt=%@\r\n",
                                                         H264_BASE_RTX,
                                                         H264_BASE_RTX,
                                                         H264_BASE];

        self.h264ProfileSdpRtx = [NSString stringWithFormat:@"a=rtpmap:%@ rtx/90000\r\n"
                                                            "a=fmtp:%@ apt=%@\r\n",
                                                            H264_PROFILE_RTX,
                                                            H264_PROFILE_RTX,
                                                            H264_PROFILE];

        self.videoCodecsFilter = [[NSSet alloc] initWithArray:@[CODEC_H264_PROFILE, CODEC_H264_BASE, CODEC_VP8, CODEC_VP9]];
    }

    return self;
}

- (NSString *)createH264Sdp:(NSString *)payload id:(NSString *)id {
    return [NSString stringWithFormat:@"a=rtpmap:%@ H264/90000\r\n"
                                      "a=rtcp-fb:%@ ccm fir\r\n"
                                      "a=rtcp-fb:%@ nack\r\n"
                                      "a=rtcp-fb:%@ nack pli\r\n"
                                      "a=rtcp-fb:%@ goog-remb\r\n"
                                      "a=rtcp-fb:%@ transport-cc\r\n"
                                      "a=fmtp:%@ level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=%@\r\n"
            , payload, payload, payload, payload, payload, payload, payload, id];
}

- (BOOL)isSupportCodec:(NSString *)sdp codec:(NSString *)codec {
    NSRange matchRange = [sdp rangeOfString:[NSString stringWithFormat:@"a=rtpmap:[0-9]+ %@", codec]
                                    options:NSRegularExpressionSearch];
    return matchRange.location != NSNotFound;
}

- (NSSet *)supportVideoCodecs:(NSString *)sdp {
    NSMutableSet *supportVideoCodecs = [[NSMutableSet alloc] initWithCapacity:10];
    NSRange matchRange = [sdp rangeOfString:@"m=video" options:NSRegularExpressionSearch];
    if (matchRange.location == NSNotFound) return NULL;

    NSError *error = nil;
    NSRegularExpression *codecSearcher = [NSRegularExpression regularExpressionWithPattern:@"a=rtpmap:\\d+ (\\w+)"
                                                                                   options:0
                                                                                     error:&error];

    NSArray *codecsRange = [codecSearcher matchesInString:sdp
                                                  options:0
                                                    range:NSMakeRange(matchRange.location, sdp.length - matchRange.location)];
    for (NSTextCheckingResult *codecResult in codecsRange) {
        NSString *codecName = [sdp substringWithRange:[codecResult rangeAtIndex:1]];
        if ([codecName isEqualToString:@"H264"]) {
            NSRegularExpression *h264Searcher = [NSRegularExpression regularExpressionWithPattern:@"profile-level-id=((\\w{2})\\w{4})"
                                                                                          options:0
                                                                                            error:&error];
            NSArray *h264Range = [h264Searcher matchesInString:sdp
                                                       options:0
                                                         range:NSMakeRange(matchRange.location, sdp.length - matchRange.location)];

            for (NSTextCheckingResult *h264Result in h264Range) {
                NSString *h264Type = [sdp substringWithRange:[h264Result rangeAtIndex:2]];
                NSString *h264Id = [sdp substringWithRange:[h264Result rangeAtIndex:1]];
                if ([h264Type isEqualToString:@"64"]) {
                    [supportVideoCodecs addObject:CODEC_H264_PROFILE];
                    self.h264ProfileId = h264Id;
                } else if ([h264Type isEqualToString:@"42"]) {
                    [supportVideoCodecs addObject:CODEC_H264_BASE];
                    self.h264BaseId = h264Id;
                } else
                    [NSException raise:@"Invalid H264 type"
                                format:@"H264 type is %@.",
                                       [sdp substringWithRange:[h264Result rangeAtIndex:1]]];
            }

        } else if ([codecName isEqualToString:@"rtx"]) {
            // ignore
        } else {
            [supportVideoCodecs addObject:codecName];
        }
    }

    [supportVideoCodecs intersectSet:self.videoCodecsFilter];

    return supportVideoCodecs;
}

- (NSString *)uniformOfferSDPCodecsPayload:(NSString *)sdp codecs:(NSArray *)codecs {
    NSMutableSet *deviceSupportCodecs = [[NSMutableSet alloc] initWithSet:[self supportVideoCodecs:sdp]];
    if ([deviceSupportCodecs count] == 0) return sdp;

    [deviceSupportCodecs intersectSet:[[NSSet alloc] initWithArray:codecs]];

    NSMutableArray *deviceSupportCodecsWithOrderInCodecs = [[NSMutableArray alloc] initWithCapacity:10];
    for (NSString *codecName in codecs) {
        if ([deviceSupportCodecs containsObject:codecName]) [deviceSupportCodecsWithOrderInCodecs addObject:codecName];
    }

    return [self updatePayload:sdp deviceCodecs:deviceSupportCodecsWithOrderInCodecs];
}

- (NSString *)rearrangeAnswerPayloadOrder:(NSString *)sdp codecs:(NSArray *)codecs{
    NSMutableSet *supportCodecSet = [[NSMutableSet alloc] initWithSet:[self supportVideoCodecs:sdp]];
    if([supportCodecSet count] == 0) return sdp;

    NSSet *customCodecSet = [[NSSet alloc] initWithArray:codecs];
    [supportCodecSet intersectSet:customCodecSet];

    NSMutableArray *supportCodecs = [NSMutableArray new];
    for(NSString *codec in codecs){
        if([supportCodecSet containsObject:codec]) [supportCodecs addObject:codec];
    }
    NSArray *reverseSupportCodecs = [[supportCodecs reverseObjectEnumerator] allObjects];

    NSMutableArray *answerCodecsSequence = [NSMutableArray new];

    if([self isSupportCodec:sdp codec:@"ulpfec"]) [answerCodecsSequence addObject:ULPFEC];
    if([self isSupportCodec:sdp codec:@"red"]) {
        [answerCodecsSequence insertObject:RED atIndex:0];
        [answerCodecsSequence addObject:RED_RTX];
    }

    for(NSString *codec in reverseSupportCodecs){
        if([codec isEqualToString:CODEC_VP8]){
            [answerCodecsSequence insertObject:VP8 atIndex:0];
            if(RTX_ENABLED) [answerCodecsSequence addObject:VP8_RTX];
        } else if ([codec isEqualToString:CODEC_VP9]){
            [answerCodecsSequence insertObject:VP9 atIndex:0];
            if(RTX_ENABLED) [answerCodecsSequence addObject:VP9_RTX];
        } else if ([codec isEqualToString:CODEC_H264_BASE]){
            [answerCodecsSequence insertObject:H264_BASE atIndex:0];
            if(RTX_ENABLED) [answerCodecsSequence addObject:H264_BASE_RTX];
        } else if ([codec isEqualToString:CODEC_H264_PROFILE]){
            [answerCodecsSequence insertObject:H264_PROFILE atIndex:0];
            [answerCodecsSequence addObject:H264_PROFILE_RTX];
        } else{
            [NSException raise:@"Unknow SDP Codec" format:@"Sdp codec %@ is unknow", codec];
        }
    }

    return [sdp stringByReplacingOccurrencesOfString:@"(m=video \\d+ .*? )(\\d.*\\d)"
                                          withString:[NSString stringWithFormat:@"$1%@", [answerCodecsSequence componentsJoinedByString:@" "]]
                                             options:NSRegularExpressionSearch
                                               range:NSMakeRange(0, sdp.length)];
}

- (NSString *)changeBwWithSdp:(NSString *)sdp bw:(NSUInteger)bw {
    NSRange videoRange = [self findVideoRangeWithSdp:sdp];
    return [sdp stringByReplacingOccurrencesOfString:@"(b=AS:)(\\d+)\r\n(b=TIAS:)(\\d+)\r\n"
                                   withString:[NSString stringWithFormat:@"$1%lu\r\n$3%lu\r\n", bw, bw * 1000]
                                      options:NSRegularExpressionSearch
                                        range:videoRange];
};


- (NSString *)adjustStreamsWithSdp:(NSString *)sdp
                            remove:(NSSet *)remove
                               add:(NSSet *)add
                            rtxMap:(NSDictionary *)rtxMap
                            finish:(void (^)(NSDictionary *))finish {
    NSArray *lines = [sdp componentsSeparatedByString:@"\r\n"];
    NSMutableDictionary *ssrc2msid = [NSMutableDictionary new];

    NSMutableArray *rtnLines = [NSMutableArray new];

    // remove lines
    for(int i = 0; i < [lines count]; i++){
        NSString *line = lines[i];
        __block BOOL findSsrc = NO;
        [remove enumerateObjectsUsingBlock:^(NSNumber *ssrc, BOOL *stop) {
            *stop = findSsrc = [line containsString:[ssrc stringValue]];
        }];
        if(!findSsrc) [rtnLines addObject:line];
    }

    // add lines
    NSMutableArray *ssrcTUuids = [NSMutableArray new];
    for(NSNumber *ssrc in add){
        NSString *cname = [[NSUUID UUID] UUIDString];
        NSString *msLabel = [[NSUUID UUID] UUIDString];
        ssrc2msid[ssrc] = msLabel;
        NSString *label = [[NSUUID UUID] UUIDString];

        [rtnLines insertObject:[NSString stringWithFormat:@"a=ssrc-group:FID %@ %@", [ssrc stringValue], rtxMap[[ssrc stringValue]]]
                       atIndex:[rtnLines count] - 1];
        [rtnLines insertObject:[NSString stringWithFormat:@"a=ssrc:%@ cname:%@", [ssrc stringValue], cname]
                       atIndex:[rtnLines count] - 1];
        [rtnLines insertObject:[NSString stringWithFormat:@"a=ssrc:%@ msid:%@ %@", [ssrc stringValue], msLabel, label]
                       atIndex:[rtnLines count] - 1];
        [rtnLines insertObject:[NSString stringWithFormat:@"a=ssrc:%@ cname:%@", rtxMap[[ssrc stringValue]], cname]
                       atIndex:[rtnLines count] - 1];
        [rtnLines insertObject:[NSString stringWithFormat:@"a=ssrc:%@ msid:%@ %@", rtxMap[[ssrc stringValue]], msLabel, label]
                       atIndex:[rtnLines count] - 1];
        [ssrcTUuids addObject:@{
            @"ssrc": ssrc,
            @"cname": cname,
            @"msLabel": msLabel,
            @"label": label
        }];
    }

    if(finish) finish(ssrc2msid);
    return [rtnLines componentsJoinedByString:@"\r\n"];
}

- (NSString *)addAttributesForPresentWithSdp:(NSString *)sdp{
    return [sdp stringByReplacingOccurrencesOfString:@"\r\n"
                                          withString:@"\r\na=content:slides\r\n"
                                             options:NSBackwardsSearch
                                               range:NSMakeRange(sdp.length - 2, 2)];
}

#pragma mark -- private funcitons

- (NSString *)updatePayload:(NSString *)sdp deviceCodecs:(NSArray *)codecs {
    NSMutableArray *codecsSequence = [[NSMutableArray alloc] initWithCapacity:20];
    NSMutableArray *codecsSdp = [[NSMutableArray alloc] initWithCapacity:20];

    NSArray *rCodecs = [[codecs reverseObjectEnumerator] allObjects];

    if (RED_ENABLED) {
        if (RTX_ENABLED) {
            [codecsSequence addObject:RED_RTX];
            [codecsSdp addObject:self.redSdpRtx];
        }
        [codecsSequence insertObject:RED atIndex:0];
        [codecsSdp insertObject:self.redSdp atIndex:0];
    }
    if (ULPFED_ENABLED) {
        [codecsSequence insertObject:ULPFEC atIndex:0];
        [codecsSdp addObject:self.ulpfecSdp];
    }
    for (NSString *codec in rCodecs) {
        if ([codec isEqualToString:@"VP8"]) {
            if (RTX_ENABLED) {
                [codecsSequence addObject:VP8_RTX];
                [codecsSdp insertObject:self.vp8SdpRtx atIndex:0];
            }
            [codecsSequence insertObject:VP8 atIndex:0];
            [codecsSdp insertObject:self.vp8Sdp atIndex:0];
        } else if ([codec isEqualToString:@"VP9"]) {
            if (RTX_ENABLED) {
                [codecsSequence addObject:VP9_RTX];
                [codecsSdp insertObject:self.vp9SdpRtx atIndex:0];
            }
            [codecsSequence insertObject:VP9 atIndex:0];
            [codecsSdp insertObject:self.vp9Sdp atIndex:0];
        } else if ([codec isEqualToString:@"H264_BASE"]) {
            if (RTX_ENABLED) {
                [codecsSequence addObject:H264_BASE_RTX];
                [codecsSdp insertObject:self.h264BaseSdpRtx atIndex:0];
            }
            [codecsSequence insertObject:H264_BASE atIndex:0];
            [codecsSdp insertObject:[self createH264Sdp:H264_BASE id:self.h264BaseId] atIndex:0];
        } else if ([codec isEqualToString:@"H264_PROFILE"]) {
            if (RTX_ENABLED) {
                [codecsSequence addObject:H264_PROFILE_RTX];
                [codecsSdp insertObject:self.h264ProfileSdpRtx atIndex:0];
            }
            [codecsSequence insertObject:H264_PROFILE atIndex:0];
            [codecsSdp insertObject:[self createH264Sdp:H264_PROFILE id:self.h264ProfileId] atIndex:0];
        } else {
            [NSException raise:@"Unknow codec type" format:@"Codec type is %@", codec];
        }
    }

    NSRange videoRange = [self findVideoRangeWithSdp:sdp];


    if (videoRange.location == NSNotFound)
        [NSException raise:@"SDP error"
                    format:@"not found Video line in SDP"];

    sdp = [sdp stringByReplacingOccurrencesOfString:@"(m=video \\d+ UDP/TLS/RTP/SAVPF ).*\r\n"
                                         withString:[NSString stringWithFormat:@"$1%@\r\n", [codecsSequence componentsJoinedByString:@" "]]
                                            options:NSRegularExpressionSearch
                                              range:NSMakeRange(videoRange.location, videoRange.length)];


    sdp = [sdp stringByReplacingOccurrencesOfString:@"(m=video \\d+ RTP/S*AVPF ).*\r\n"
                                         withString:[NSString stringWithFormat:@"$1%@\r\n", [codecsSequence componentsJoinedByString:@" "]]
                                            options:NSRegularExpressionSearch
                                              range:NSMakeRange(0, sdp.length)];

    NSError *error = nil;
    NSRegularExpression *codecLineRegex = [NSRegularExpression regularExpressionWithPattern:@"(a=rtpmap.*\r\n|a=rtcp-fb:.*\r\n|a=fmtp:.*\r\n)"
                                                                                    options:0
                                                                                      error:&error];

    videoRange = [self findVideoRangeWithSdp:sdp];
    NSArray *codecLines = [codecLineRegex matchesInString:sdp
                                                  options:0
                                                    range:NSMakeRange(videoRange.location, videoRange.length)];

    NSUInteger codecLocation = [[codecLines firstObject] rangeAtIndex:0].location;
    NSUInteger codecLength = NSMaxRange([[codecLines lastObject] rangeAtIndex:0]) - codecLocation;

    return [sdp stringByReplacingCharactersInRange:NSMakeRange(codecLocation, codecLength) withString:[codecsSdp componentsJoinedByString:@""]];
}

- (NSRange)findVideoRangeWithSdp:(NSString *)sdp {
    NSRange videoLine = [sdp rangeOfString:@"m=video"];
    NSRange audioLine = [sdp rangeOfString:@"m=audio"];
    NSUInteger videoLength = audioLine.location != NSNotFound && audioLine.location > videoLine.location
            ? audioLine.location - videoLine.location
            : sdp.length - videoLine.location;
    return NSMakeRange(videoLine.location, videoLength);
}

/*
 * video ssrc: high 1000, low 1001
 * */
- (NSString *)modifySsrcValueWithSdp:(NSString *)sdp{
    NSError *error = nil;
    NSString *rtn = nil;
    NSRegularExpression *codecSearcher = [NSRegularExpression regularExpressionWithPattern:@"a=ssrc-group:FID (\\d+) \\d+"
                                                                                   options:0
                                                                                     error:&error];
    NSArray *range = [codecSearcher matchesInString:sdp options:0 range:NSMakeRange(0, sdp.length)];
    NSInteger targetSsrc = 1000 + [range count] - 1;
    for (NSTextCheckingResult *result in [[range reverseObjectEnumerator] allObjects]){
        NSString *ssrc = [sdp substringWithRange:[result rangeAtIndex:1]];
        sdp = [sdp stringByReplacingOccurrencesOfString:ssrc
                                             withString:[NSString stringWithFormat:@"%ld", (long)targetSsrc-- ]
                                                options:0
                                                  range:NSMakeRange(0, sdp.length)];
    }
    rtn = sdp;
    return rtn;
}

- (NSString *)useCryptoMethodWithSdp:(NSString *)sdp{
    NSString *rtnSdp = [sdp stringByReplacingOccurrencesOfString:@"(m=\\w+ \\d+ )(UDP/TLS/)(RTP/SAVPF)"
                                                      withString:@"$1$3"
                                                         options:NSRegularExpressionSearch
                                                           range:NSMakeRange(0, sdp.length)];
    rtnSdp = [rtnSdp stringByReplacingOccurrencesOfString:@"a=rtcp-mux\r\n"
                                               withString:@"a=rtcp-mux\r\na=crypto:0 AES_CM_128_HMAC_SHA1_80 inline:FwWzrBwEjxpvK+MCxzGnBmSIcHpp540Hn9xGP63x\r\n"];
    rtnSdp = [rtnSdp stringByReplacingOccurrencesOfString:@"a=fingerprint.*\r\n"
                                               withString:@""
                                                  options:NSRegularExpressionSearch
                                                    range:NSMakeRange(0, rtnSdp.length)];
    rtnSdp = [rtnSdp stringByReplacingOccurrencesOfString:@"a=ice-options:trickle renomination\r\n"
                                               withString:@"a=ice-options:trickle\r\n"];
    return  rtnSdp;
}
@end
